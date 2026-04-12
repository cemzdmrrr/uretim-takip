// ignore_for_file: invalid_use_of_protected_member
part of 'dokuma_dashboard.dart';

/// Dokuma dashboard rapor ve filtre dialog'ları
extension _RaporFiltreExt on _DokumaDashboardState {
  void _showRaporDialog() {
    String? filtreliMarka;
    String? filtreliModel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tumModeller = [...bekleyenModeller, ...onaylanmisModeller, ...uretimdeOlanModeller, ...tamamlananModeller];
          
          // Filtreleme uygula
          List<Map<String, dynamic>> filtreliModeller = tumModeller;
          
          if (filtreliMarka != null && filtreliMarka!.isNotEmpty) {
            filtreliModeller = filtreliModeller.where((a) {
              final model = a[DbTables.trikoTakip] as Map<String, dynamic>?;
              return model != null && model['marka'] == filtreliMarka;
            }).toList();
          }
          
          if (filtreliModel != null && filtreliModel!.isNotEmpty) {
            filtreliModeller = filtreliModeller.where((a) {
              final model = a[DbTables.trikoTakip] as Map<String, dynamic>?;
              if (model == null) return false;
              final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
              return itemNo.contains(filtreliModel!.toLowerCase());
            }).toList();
          }
          
          // İstatistikler - Model bazında hesapla
          final Map<String, Map<String, dynamic>> modelBazliVeriler = {};
          
          for (var atama in filtreliModeller) {
            final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
            if (model != null) {
              final modelId = model['id'];
              if (!modelBazliVeriler.containsKey(modelId)) {
                modelBazliVeriler[modelId] = {
                  'siparis_adedi': (model['adet'] ?? 0) as int,
                  'tamamlanan': 0,
                  'marka': model['marka']?.toString() ?? 'Bilinmeyen',
                };
              }
              modelBazliVeriler[modelId]!['tamamlanan'] += (atama['tamamlanan_adet'] ?? 0) as int;
            }
          }
          
          final int toplamModel = modelBazliVeriler.length;
          int toplamAdet = 0;
          int tamamlananAdet = 0;
          int bekleyenAdet = 0;
          int toplamFire = 0;
          final Map<String, int> markaBasinaModel = {};
          final Map<String, int> markaBasinaAdet = {};
          
          for (var veri in modelBazliVeriler.values) {
            final siparisAdedi = veri['siparis_adedi'] as int;
            final tamamlanan = veri['tamamlanan'] as int;
            final marka = veri['marka'] as String;
            
            toplamAdet += siparisAdedi;
            tamamlananAdet += tamamlanan;
            bekleyenAdet += (siparisAdedi - tamamlanan).clamp(0, siparisAdedi);
            
            markaBasinaModel[marka] = (markaBasinaModel[marka] ?? 0) + 1;
            markaBasinaAdet[marka] = (markaBasinaAdet[marka] ?? 0) + siparisAdedi;
          }
          
          // Fire hesapla (tüm atamalardan)
          for (var atama in filtreliModeller) {
            toplamFire += (atama['fire_adet'] ?? 0) as int;
          }
          
          final tamamlanmaOrani = toplamAdet > 0 ? ((tamamlananAdet / toplamAdet) * 100) : 0.0;
          final fireOrani = (tamamlananAdet + toplamFire) > 0 ? ((toplamFire / (tamamlananAdet + toplamFire)) * 100) : 0.0;
          
          final Map<String, int> durumBasinaModel = {
            'Bekleyen': bekleyenModeller.length,
            'Onaylanan': onaylanmisModeller.length,
            'Üretimde': uretimdeOlanModeller.length,
            'Tamamlanan': tamamlananModeller.length,
          };
          
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('Dokuma Raporu'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filtreler
                    Card(
                      color: Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔍 Filtreler', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Marka',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    initialValue: filtreliMarka,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                                      ...markalar.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                                    ],
                                    onChanged: (v) => setDialogState(() => filtreliMarka = v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Model Ara',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (v) => setDialogState(() => filtreliModel = v.isEmpty ? null : v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Özet istatistikler
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📊 Genel Özet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            _buildRaporSatiri('Toplam Model', toplamModel.toString()),
                            _buildRaporSatiri('Toplam Sipariş Adedi', toplamAdet.toString()),
                            _buildRaporSatiri('Tamamlanan Adet', tamamlananAdet.toString()),
                            _buildRaporSatiri('Bekleyen Adet', bekleyenAdet.toString()),
                            _buildRaporSatiri('Toplam Fire', toplamFire.toString()),
                            _buildRaporSatiri('Tamamlanma Oranı', '%${tamamlanmaOrani.toStringAsFixed(1)}'),
                            if (toplamFire > 0)
                              _buildRaporSatiri('Fire Oranı', '%${fireOrani.toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Durum dağılımı
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📈 Durum Dağılımı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            ...durumBasinaModel.entries.map((e) => _buildRaporSatiri(e.key, e.value.toString())),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Marka dağılımı
                    if (markaBasinaModel.isNotEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🏷️ Marka Dağılımı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Divider(),
                              ...markaBasinaModel.entries.map((e) => 
                                _buildRaporSatiri(e.key, '${e.value} model (${markaBasinaAdet[e.key] ?? 0} adet)')),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRaporSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Filtre dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Filtrele'),
            ],
          ),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Marka seçimi
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  initialValue: seciliMarka,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    ...markalar.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (value) {
                    setDialogState(() => seciliMarka = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Başlangıç tarihi
                ListTile(
                  title: const Text('Başlangıç Tarihi'),
                  subtitle: Text(baslangicTarihi != null 
                      ? DateFormat('dd.MM.yyyy').format(baslangicTarihi!) 
                      : 'Seçilmedi'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: baslangicTarihi ?? DateTime.now().subtract(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() => baslangicTarihi = date);
                          }
                        },
                      ),
                      if (baslangicTarihi != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setDialogState(() => baslangicTarihi = null),
                        ),
                    ],
                  ),
                ),
                
                // Bitiş tarihi
                ListTile(
                  title: const Text('Bitiş Tarihi'),
                  subtitle: Text(bitisTarihi != null 
                      ? DateFormat('dd.MM.yyyy').format(bitisTarihi!) 
                      : 'Seçilmedi'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: bitisTarihi ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => bitisTarihi = date);
                          }
                        },
                      ),
                      if (bitisTarihi != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setDialogState(() => bitisTarihi = null),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  seciliMarka = null;
                  baslangicTarihi = null;
                  bitisTarihi = null;
                });
              },
              child: const Text('Temizle'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Ana widget'ı güncelle
                Navigator.pop(context);
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

}
