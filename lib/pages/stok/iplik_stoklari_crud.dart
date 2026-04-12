// ignore_for_file: invalid_use_of_protected_member
part of 'iplik_stoklari.dart';

/// CRUD operations (add, edit, delete, transfer) for _IplikStoklariPageState.
extension _IplikCrudExt on _IplikStoklariPageState {

  Future<void> _yeniIplikGirisi() async {
    final adController = TextEditingController();
    final renkController = TextEditingController();
    final lotController = TextEditingController();
    final miktarController = TextEditingController();
    final birimFiyatController = TextEditingController();
    Map<String, dynamic>? seciliTedarikci;
    String seciliParaBirimi = 'TL'; // Varsayılan para birimi
    
    // İplik firması olan tedarikçileri filtrele
    final iplikTedarikcileri = tedarikciler.where((tedarikci) {
      final turu = tedarikci['tedarikci_turu']?.toString() ?? '';
      final faaliyet = tedarikci['faaliyet_alani']?.toString() ?? '';
      final sirket = tedarikci['sirket']?.toString() ?? '';
      final ad = tedarikci['ad']?.toString() ?? '';
      
      return turu == 'İplik Firması' || 
             turu.toLowerCase().contains('iplik') ||
             faaliyet.toLowerCase().contains('iplik') ||
             sirket.toLowerCase().contains('iplik') ||
             ad.toLowerCase().contains('iplik');
    }).toList();
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni İplik Girişi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: adController,
                  decoration: const InputDecoration(
                    labelText: 'İplik Adı/Türü *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: renkController,
                  decoration: const InputDecoration(
                    labelText: 'Renk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: lotController,
                  decoration: const InputDecoration(
                    labelText: 'Lot/Parti No',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: miktarController,
                  decoration: const InputDecoration(
                    labelText: 'Miktar (kg) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: birimFiyatController,
                        decoration: const InputDecoration(
                          labelText: 'Birim Fiyat',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: seciliParaBirimi,
                        decoration: const InputDecoration(
                          labelText: 'Para Birimi',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TL', child: Text('₺ TL')),
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            seciliParaBirimi = value ?? 'TL';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: seciliTedarikci,
                  decoration: const InputDecoration(
                    labelText: 'Tedarikçi (İplik Firmaları)',
                    border: OutlineInputBorder(),
                  ),
                  items: iplikTedarikcileri.isEmpty ? [] : iplikTedarikcileri.map((tedarikci) {
                    return DropdownMenuItem(
                      value: tedarikci,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${tedarikci['sirket'] ?? tedarikci['ad'] ?? 'İsimsiz'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tür: ${tedarikci['tedarikci_turu'] ?? 'Belirtilmemiş'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      seciliTedarikci = value;
                    });
                  },
                ),
                
                // İplik firması yoksa uyarı göster
                if (iplikTedarikcileri.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İplik firması bulunamadı!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                'Tedarikçiler bölümünden "İplik Firması" türünde tedarikçi ekleyin.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2B48C),
            ),
            onPressed: () async {
              try {
                if (adController.text.trim().isEmpty || miktarController.text.trim().isEmpty) {
                  throw 'İplik adı ve miktar zorunludur';
                }

                final miktar = double.tryParse(miktarController.text.trim());
                if (miktar == null || miktar <= 0) {
                  throw 'Geçerli bir miktar girin';
                }

                final birimFiyat = birimFiyatController.text.trim().isNotEmpty 
                  ? double.tryParse(birimFiyatController.text.trim()) 
                  : null;

                // İplik stok kaydı ekle
                final stokData = {
                  'ad': adController.text.trim(),
                  'renk': renkController.text.trim().isNotEmpty ? renkController.text.trim() : null,
                  'lot_no': lotController.text.trim().isNotEmpty ? lotController.text.trim() : null,
                  'miktar': miktar,
                  'birim': 'kg',
                  'birim_fiyat': birimFiyat,
                  'para_birimi': seciliParaBirimi,
                  'tedarikci_id': seciliTedarikci?['id'],
                  'firma_id': TenantManager.instance.requireFirmaId,
                };

                if (birimFiyat != null) {
                  stokData['toplam_deger'] = miktar * birimFiyat;
                }

                final stokResponse = await supabase
                    .from(DbTables.iplikStoklari)
                    .insert(stokData)
                    .select('id')
                    .single();

                // İplik hareketi ekle
                await supabase.from(DbTables.iplikHareketleri).insert({
                  'iplik_id': stokResponse['id'],
                  'hareket_tipi': 'giris',
                  'miktar': miktar,
                  'aciklama': 'İlk stok girişi',
                  'firma_id': TenantManager.instance.requireFirmaId,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  await _verileriYukle();
                  if (!context.mounted) return;
                  context.showSuccessSnackBar('İplik girişi başarıyla kaydedildi');
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
    ),
    );
  }

  Future<void> _cikisModalGoster(Map<String, dynamic> stok) async {
    final miktarController = TextEditingController();
    final aciklamaController = TextEditingController();
    String hareketTipi = 'cikis';
    Map<String, dynamic>? seciliModel;

    // Modelleri yükle
    List<Map<String, dynamic>> modeller = [];
    try {
      final modelVeri = await supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, adet')
          .filter('tamamlandi', 'is', null)
          .order('created_at', ascending: false);
      modeller = List<Map<String, dynamic>>.from(modelVeri);
    } catch (e) {
      debugPrint('Model verisi yüklenirken hata: $e');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("İplik Çıkışı - ${stok['ad']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İplik bilgileri
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("İplik: ${stok['ad']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Renk: ${stok['renk'] ?? '-'}"),
                        Text('Lot: ${stok['lot_no'] ?? '-'}'),
                        Text("Mevcut Miktar: ${stok['miktar']} ${stok['birim'] ?? 'kg'}"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: hareketTipi,
                  decoration: const InputDecoration(
                    labelText: 'Hareket Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cikis', child: Text('Çıkış/Sarf')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(value: 'sayim', child: Text('Sayım Düzeltmesi')),
                  ],
                  onChanged: (value) {
                    setState(() => hareketTipi = value ?? 'cikis');
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: miktarController,
                  decoration: const InputDecoration(
                    labelText: 'Miktar (kg) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (hareketTipi == 'cikis' && modeller.isNotEmpty)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: seciliModel,
                    decoration: const InputDecoration(
                      labelText: 'Model (Opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    items: modeller.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text('${model['marka']} ${model['item_no']} - ${model['renk']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => seciliModel = value);
                    },
                  ),
                if (hareketTipi == 'cikis' && modeller.isNotEmpty)
                  const SizedBox(height: 16),
                TextField(
                  controller: aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                  final miktar = double.tryParse(miktarController.text);
                  if (miktar == null || miktar <= 0) {
                    throw 'Geçerli bir miktar giriniz';
                  }

                  final mevcutMiktar = (stok['miktar'] as num).toDouble();
                  if (hareketTipi != 'sayim' && miktar > mevcutMiktar) {
                    throw 'Yetersiz stok miktarı. Mevcut: $mevcutMiktar kg';
                  }

                  double yeniMiktar;
                  if (hareketTipi == 'sayim') {
                    yeniMiktar = miktar; // Sayım düzeltmesinde miktar direkt olarak ayarlanır
                  } else {
                    yeniMiktar = mevcutMiktar - miktar;
                  }

                  // Stok miktarını güncelle
                  await supabase.from(DbTables.iplikStoklari).update({
                    'miktar': yeniMiktar,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', stok['id']).eq('firma_id', TenantManager.instance.requireFirmaId);

                  // Hareket kaydı ekle
                  await supabase.from(DbTables.iplikHareketleri).insert({
                    'iplik_id': stok['id'],
                    'hareket_tipi': hareketTipi,
                    'miktar': miktar,
                    'aciklama': aciklamaController.text.trim().isNotEmpty 
                      ? aciklamaController.text.trim() 
                      : null,
                    'model_id': seciliModel?['id'],
                    'firma_id': TenantManager.instance.requireFirmaId,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    await _verileriYukle();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${stok['ad']} için $miktar kg $hareketTipi kaydedildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
      ),
    );
  }

  Future<void> _stokDuzenle(Map<String, dynamic> stok) async {
    final adController = TextEditingController(text: stok['ad']);
    final renkController = TextEditingController(text: stok['renk'] ?? '');
    final lotController = TextEditingController(text: stok['lot_no'] ?? '');
    final miktarController = TextEditingController(text: stok['miktar'].toString());
    final birimFiyatController = TextEditingController(text: stok['birim_fiyat']?.toString() ?? '');
    Map<String, dynamic>? seciliTedarikci = tedarikciler.where((t) => t['id'] == stok['tedarikci_id']).isNotEmpty 
      ? tedarikciler.firstWhere((t) => t['id'] == stok['tedarikci_id'])
      : null;
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İplik Stok Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adController,
                decoration: const InputDecoration(
                  labelText: 'İplik Adı/Türü *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: renkController,
                decoration: const InputDecoration(
                  labelText: 'Renk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lotController,
                decoration: const InputDecoration(
                  labelText: 'Lot/Parti No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: miktarController,
                decoration: const InputDecoration(
                  labelText: 'Miktar (kg) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: birimFiyatController,
                decoration: const InputDecoration(
                  labelText: 'Birim Fiyat (₺)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: seciliTedarikci,
                decoration: const InputDecoration(
                  labelText: 'Tedarikçi',
                  border: OutlineInputBorder(),
                ),
                items: tedarikciler.map((tedarikci) {
                  return DropdownMenuItem(
                    value: tedarikci,
                    child: Text('${tedarikci['sirket'] ?? tedarikci['ad']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  seciliTedarikci = value;
                },
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2B48C),
            ),
            onPressed: () async {
              try {
                if (adController.text.trim().isEmpty || miktarController.text.trim().isEmpty) {
                  throw 'İplik adı ve miktar zorunludur';
                }

                final miktar = double.tryParse(miktarController.text.trim());
                if (miktar == null || miktar < 0) {
                  throw 'Geçerli bir miktar girin';
                }

                final birimFiyat = birimFiyatController.text.trim().isNotEmpty 
                  ? double.tryParse(birimFiyatController.text.trim()) 
                  : null;

                final updateData = {
                  'ad': adController.text.trim(),
                  'renk': renkController.text.trim().isNotEmpty ? renkController.text.trim() : null,
                  'lot_no': lotController.text.trim().isNotEmpty ? lotController.text.trim() : null,
                  'miktar': miktar,
                  'birim_fiyat': birimFiyat,
                  'tedarikci_id': seciliTedarikci?['id'],
                  'updated_at': DateTime.now().toIso8601String(),
                };

                if (birimFiyat != null) {
                  updateData['toplam_deger'] = miktar * birimFiyat;
                }

                await supabase
                    .from(DbTables.iplikStoklari)
                    .update(updateData)
                    .eq('id', stok['id'])
                    .eq('firma_id', TenantManager.instance.requireFirmaId);

                if (context.mounted) {
                  Navigator.pop(context);
                  await _verileriYukle();
                  if (!context.mounted) return;
                  context.showSuccessSnackBar('İplik stoku başarıyla güncellendi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _stokSil(Map<String, dynamic> stok) async {
    try {
      final onay = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('İplik Stok Sil'),
          content: Text('${stok['ad']} - ${stok['renk'] ?? 'Renk Yok'} ipliğini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      );

      if (onay == true) {
        final firmaId = TenantManager.instance.requireFirmaId;
        // Önce bu ipliğe bağlı hareketleri sil
        await supabase
            .from(DbTables.iplikHareketleri)
            .delete()
            .eq('iplik_id', stok['id'])
            .eq('firma_id', firmaId);

        // Sonra ipliği sil
        await supabase
            .from(DbTables.iplikStoklari)
            .delete()
            .eq('id', stok['id'])
            .eq('firma_id', firmaId);

        await _verileriYukle();

        if (!mounted) return;
        context.showSuccessSnackBar('İplik stoku başarıyla silindi');
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  Future<void> exportToExcel(List<Map<String, dynamic>> data, {required String fileName}) async {
    try {
      await ExcelHelper.exportToExcel(
        data: data,
        fileName: fileName,
        columns: {
          'ad': 'İplik Adı',
          'renk': 'Renk',
          'lot_no': 'Lot No',
          'miktar': 'Miktar',
          'birim': 'Birim',
          'birim_fiyat': 'Birim Fiyat',
          'toplam_deger': 'Toplam Değer',
          'created_at': 'Oluşturma Tarihi',
        },
      );
      if (mounted) {
        context.showSuccessSnackBar('Excel dosyası başarıyla oluşturuldu');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Excel oluşturulurken hata: $e');
      }
    }
  }
}
