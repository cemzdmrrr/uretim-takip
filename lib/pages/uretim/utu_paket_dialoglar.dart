// ignore_for_file: invalid_use_of_protected_member
part of 'utu_paket_dashboard.dart';

/// Utility dialogs (search, filter, report) for _UtuPaketDashboardState.
extension _DialoglarExt on _UtuPaketDashboardState {
  // ============ DİALOGLAR ============

  void _aramaDialoguGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ara'),
        content: TextField(
          controller: _aramaController,
          decoration: const InputDecoration(
            hintText: 'Marka, model veya renk ara...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            setState(() => aramaMetni = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                aramaMetni = '';
                _aramaController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => aramaMetni = _aramaController.text);
              Navigator.pop(context);
            },
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }

  void _filtreDialoguGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: seciliMarka,
              decoration: const InputDecoration(
                  labelText: 'Marka', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tümü')),
                ...markalar
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (value) => setState(() => seciliMarka = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => seciliMarka = null);
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _raporDialoguGoster() {
    String? filtreliMarka;
    String? filtreliModel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filtreleme uygula
          final List<Map<String, dynamic>> tumAtamalar = [
            ...utuBekleyenler,
            ...utuOnaylananlar,
            ...utuUretimde,
            ...utuTamamlananlar,
            ...paketBekleyenler,
            ...paketOnaylananlar,
            ...paketUretimde,
            ...paketTamamlananlar,
          ];

          List<Map<String, dynamic>> filtreliModeller = tumAtamalar;

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

          // İstatistikleri hesapla
          final int toplamModel = filtreliModeller.length;
          int toplamAdet = 0;
          int tamamlananAdet = 0;
          final Map<String, int> markaBasinaModel = {};
          final Map<String, int> markaBasinaAdet = {};

          for (var atama in filtreliModeller) {
            final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
            if (model != null) {
              final adet = ((model['adet'] ?? model['toplam_adet'] ?? 0) as num).toInt();
              toplamAdet += adet;

              final marka = model['marka']?.toString() ?? 'Bilinmeyen';
              markaBasinaModel[marka] = (markaBasinaModel[marka] ?? 0) + 1;
              markaBasinaAdet[marka] = (markaBasinaAdet[marka] ?? 0) + adet;
            }

            tamamlananAdet += ((atama['tamamlanan_adet'] ?? 0) as num).toInt();
          }

          final bekleyenAdet = toplamAdet - tamamlananAdet;
          final tamamlanmaOrani = toplamAdet > 0 ? ((tamamlananAdet / toplamAdet) * 100) : 0.0;

          // Durum dağılımı - Ütü
          final toplamUtu = utuBekleyenler.length + utuOnaylananlar.length + utuUretimde.length + utuTamamlananlar.length;
          final Map<String, int> utuDurumlari = {
            'Bekleyen': utuBekleyenler.length,
            'Onaylanan': utuOnaylananlar.length,
            'Üretimde': utuUretimde.length,
            'Tamamlanan': utuTamamlananlar.length,
          };

          // Durum dağılımı - Paketleme
          final toplamPaket = paketBekleyenler.length + paketOnaylananlar.length + paketUretimde.length + paketTamamlananlar.length;
          final Map<String, int> paketDurumlari = {
            'Bekleyen': paketBekleyenler.length,
            'Onaylanan': paketOnaylananlar.length,
            'Üretimde': paketUretimde.length,
            'Tamamlanan': paketTamamlananlar.length,
          };

          // Çeki istatistikleri
          final bekleyenCeki = cekiListesi.where((c) => c['gonderim_durumu'] != 'gonderildi').length;
          final gonderilenCeki = cekiListesi.where((c) => c['gonderim_durumu'] == 'gonderildi').length;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.analytics, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text('Ütü Paket Raporu'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    // Genel Özet
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📊 Genel Özet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            _buildRaporRow('Toplam Model', toplamModel),
                            _buildRaporRow('Toplam Sipariş Adedi', toplamAdet),
                            _buildRaporRow('Tamamlanan Adet', tamamlananAdet),
                            _buildRaporRow('Bekleyen Adet', bekleyenAdet),
                            _buildRaporSatiri('Tamamlanma Oranı', '%${tamamlanmaOrani.toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ütü Dağılımı
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔥 Ütü Durum Dağılımı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            ...utuDurumlari.entries.map((e) => _buildRaporRow(e.key, e.value)),
                            const Divider(),
                            _buildRaporRow('Toplam', toplamUtu),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Paketleme Dağılımı
                    Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📦 Paketleme Durum Dağılımı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            ...paketDurumlari.entries.map((e) => _buildRaporRow(e.key, e.value)),
                            const Divider(),
                            _buildRaporRow('Toplam', toplamPaket),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Çeki Listesi İstatistikleri
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📋 Çeki Listesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            _buildRaporRow('Toplam Kayıt', cekiListesi.length),
                            _buildRaporRow('Bekleyen Gönderi', bekleyenCeki),
                            _buildRaporRow('Gönderilen', gonderilenCeki),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Marka Dağılımı
                    if (markaBasinaModel.isNotEmpty)
                      Card(
                        color: Colors.green.shade50,
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRaporRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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

  void _hataGoster(String mesaj) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
      );
    }
  }
}
