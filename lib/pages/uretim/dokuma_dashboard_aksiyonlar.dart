// ignore_for_file: invalid_use_of_protected_member
part of 'dokuma_dashboard.dart';

/// Dokuma dashboard beden fire, duzenleme, tamamlama, uretim ve kabul/red islemleri
extension _AksiyonlarDokumaExt on _DokumaDashboardState {
  void _showBedenFireDetay(Map<String, dynamic> atama, Map<String, dynamic> model) async {
    final atamaId = atama['id'] as int;
    final modelId = model['id']?.toString() ?? atama['model_id']?.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text('Fire Detayı - ${model['item_no']}')),
          ],
        ),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getBedenFireVerileri(atamaId, modelId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}');
            }
            
            final veriler = snapshot.data ?? [];
            
            if (veriler.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Beden bazlı fire verisi bulunamadı.'),
              );
            }
            
            int toplamUretilen = 0;
            int toplamFire = 0;
            for (final v in veriler) {
              toplamUretilen += (v['uretilen_adet'] ?? 0) as int;
              toplamFire += (v['fire_adet'] ?? 0) as int;
            }
            
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Özet
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Toplam Üretim', style: TextStyle(fontSize: 11)),
                            Text('$toplamUretilen', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Toplam Fire', style: TextStyle(fontSize: 11, color: Colors.red)),
                            Text('$toplamFire', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Fire Oranı', style: TextStyle(fontSize: 11)),
                            Text(
                              toplamUretilen + toplamFire > 0 
                                  ? '%${((toplamFire / (toplamUretilen + toplamFire)) * 100).toStringAsFixed(1)}'
                                  : '%0',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Beden bazlı tablo
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: const [
                          Padding(padding: EdgeInsets.all(8), child: Text('Beden', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Üretilen', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Fire', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Oran', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...veriler.map((v) {
                        final uretilen = (v['uretilen_adet'] ?? 0) as int;
                        final fire = (v['fire_adet'] ?? 0) as int;
                        final oran = uretilen + fire > 0 
                            ? ((fire / (uretilen + fire)) * 100).toStringAsFixed(1)
                            : '0.0';
                        return TableRow(
                          decoration: fire > 0 ? BoxDecoration(color: Colors.red.shade50) : null,
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(v['beden_kodu'] ?? '-')),
                            Padding(padding: const EdgeInsets.all(8), child: Text('$uretilen')),
                            Padding(padding: const EdgeInsets.all(8), child: Text('$fire', style: fire > 0 ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold) : null)),
                            Padding(padding: const EdgeInsets.all(8), child: Text('%$oran')),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBedenFireVerileri(int atamaId, String modelId) async {
    try {
      final response = await supabase
          .from(DbTables.dokumaBedeTakip)
          .select('beden_kodu, uretilen_adet, fire_adet')
          .eq('atama_id', atamaId)
          .order('beden_kodu');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Beden fire verisi alınamadı: $e');
      return [];
    }
  }

  // Düzenle Dialog'u
  void _showDuzenleDialog(Map<String, dynamic> atama, Map<String, dynamic> model) {
    final notlarController = TextEditingController(text: atama['notlar'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atama Düzenle - ${model['marka']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model: ${model['item_no']}'),
              Text('Renk: ${model['renk'] ?? '-'}'),
              const SizedBox(height: 16),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(
                  labelText: 'Notlar',
                  border: OutlineInputBorder(),
                  helperText: 'Üretime ilişkin notlar',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase
                    .from(DbTables.dokumaAtamalari)
                    .update({'notlar': notlarController.text})
                    .eq('id', atama['id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();
                
                if (mounted) {
                  context.showSuccessSnackBar('✅ Atama güncellendi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Üretimi Tamamla Dialog'u - BEDEN BAZLI
  void _showTamamlaDialog(Map<String, dynamic> atama, Map<String, dynamic> model) {
    final modelId = model['id']?.toString() ?? atama['model_id']?.toString() ?? '';
    final atamaId = atama['id'] as int;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BedenUretimTamamlaDialog(
        modelId: modelId,
        modelAdi: '${model['marka']} - ${model['item_no']}',
        atamaId: atamaId,
        atama: atama,
        model: model,
        supabase: supabase,
        onComplete: () {
          _modelleriGetir();
        },
      ),
    );
  }

  // Üretime Al Dialog'u - onaylanan işleri üretime başlatır
  void _showUretimeAlDialog(Map<String, dynamic> atama, Map<String, dynamic> model) {
    DateTime planlananBitisTarihi = DateTime.now().add(const Duration(days: 7)); // Varsayılan 1 hafta
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.purple.shade600),
                ),
                const SizedBox(width: 12),
                const Text('Üretime Al'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${model['marka']} - ${model['item_no']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Renk: ${model['renk'] ?? '-'}'),
                        Text('Kabul Edilen: ${atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? '-'} adet'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // Planlanan bitiş tarihi seçimi
                  const Text('Planlanan Bitiş Tarihi',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: planlananBitisTarihi,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('tr', 'TR'),
                      );
                      if (picked != null) {
                        setDialogState(() => planlananBitisTarihi = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.purple.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.purple.shade600),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr').format(planlananBitisTarihi),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit, color: Colors.purple.shade400, size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Hızlı tarih seçenekleri
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickDateChip('1 Hafta', 7, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('2 Hafta', 14, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('1 Ay', 30, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('2 Ay', 60, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await supabase
                        .from(DbTables.dokumaAtamalari)
                        .update({
                          'durum': 'uretimde',
                          'baslama_tarihi': DateTime.now().toIso8601String(),
                          'planlanan_bitis_tarihi': planlananBitisTarihi.toIso8601String(),
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', atama['id']);
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _modelleriGetir();
                    
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${model['marka']} - ${model['item_no']} üretime alındı'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    context.showErrorSnackBar('Hata: $e');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Üretime Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hızlı tarih seçim chip'i
  Widget _buildQuickDateChip(String label, int days, DateTime currentDate, Function(int) onSelect) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected = currentDate.difference(targetDate).inDays.abs() < 1;
    
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Colors.purple.shade100 : Colors.grey.shade200,
      side: BorderSide(
        color: isSelected ? Colors.purple.shade400 : Colors.grey.shade400,
      ),
      onPressed: () => onSelect(days),
    );
  }

  // Kabul Et Dialog'u
  void _showKabulDialog(Map<String, dynamic> atama, Map<String, dynamic> model) {
    final adetController = TextEditingController(
      text: (atama['talep_edilen_adet'] ?? atama['adet'] ?? 0).toString()
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Kabul Et'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model: ${model['marka']} - ${model['item_no']}'),
              Text('Talep Edilen: ${atama['talep_edilen_adet'] ?? atama['adet']} adet'),
              const SizedBox(height: 16),
              TextField(
                controller: adetController,
                decoration: const InputDecoration(
                  labelText: 'Kabul Edilen Adet',
                  border: OutlineInputBorder(),
                  helperText: 'Tamamlayabileceğiniz adet miktarı',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final kabulAdet = int.tryParse(adetController.text) ?? 0;
                if (kabulAdet <= 0) {
                  throw Exception('Geçerli bir adet giriniz');
                }
                
                await supabase
                    .from(DbTables.dokumaAtamalari)
                    .update({
                      'kabul_edilen_adet': kabulAdet,
                      'durum': 'onaylandi',
                    })
                    .eq('id', atama['id']);
                
                // Model durumunu güncelle - üretim başladı
                await supabase
                    .from(DbTables.trikoTakip)
                    .update({'durum': 'üretim başladı'})
                    .eq('id', atama['model_id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();
                
                if (mounted) {
                  context.showSuccessSnackBar('✅ $kabulAdet adet kabul edildi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
  }

  // Reddet Dialog'u
  void _showReddetDialog(Map<String, dynamic> atama) {
    final sebebController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu atamayı reddetmek istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            TextField(
              controller: sebebController,
              decoration: const InputDecoration(
                labelText: 'Red Sebebi',
                border: OutlineInputBorder(),
                helperText: 'Reddetme nedeninizi yazın',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (sebebController.text.isEmpty) {
                  throw Exception('Lütfen red sebebini belirtin');
                }
                
                await supabase
                    .from(DbTables.dokumaAtamalari)
                    .update({
                      'durum': 'reddedildi',
                      'notlar': '[RED SEBEBİ] ${sebebController.text}',
                    })
                    .eq('id', atama['id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();
                
                if (mounted) {
                  context.showErrorSnackBar('❌ Atama reddedildi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }
}
