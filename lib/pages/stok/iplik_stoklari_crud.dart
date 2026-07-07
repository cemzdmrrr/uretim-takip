// ignore_for_file: invalid_use_of_protected_member
part of 'iplik_stoklari.dart';

/// CRUD operations (add, edit, delete, transfer) for _IplikStoklariPageState.
extension _IplikCrudExt on _IplikStoklariPageState {
  Future<Map<String, dynamic>?> _stokHareketiKaydet({
    String? iplikId,
    Map<String, dynamic>? stokData,
    required String hareketTipi,
    required double miktar,
    String? aciklama,
    String? modelId,
  }) async {
    final response = await supabase.rpc(
      'iplik_stok_hareket_kaydet',
      params: {
        'p_firma_id': TenantManager.instance.requireFirmaId,
        'p_iplik_id': iplikId,
        'p_stok_data': stokData,
        'p_hareket_tipi': hareketTipi,
        'p_miktar': miktar,
        'p_aciklama': aciklama,
        'p_model_id': modelId,
      },
    );

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return null;
  }

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
                  items: iplikTedarikcileri.isEmpty
                      ? []
                      : iplikTedarikcileri.map((tedarikci) {
                          return DropdownMenuItem(
                            value: tedarikci,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tedarikci['sirket'] ?? tedarikci['ad'] ?? 'İsimsiz'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tür: ${tedarikci['tedarikci_turu'] ?? 'Belirtilmemiş'}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
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
                  if (adController.text.trim().isEmpty ||
                      miktarController.text.trim().isEmpty) {
                    throw 'İplik adı ve miktar zorunludur';
                  }

                  final miktar = _parseDecimal(miktarController.text);
                  if (miktar == null || miktar <= 0) {
                    throw 'Geçerli bir miktar girin';
                  }

                  final birimFiyat = birimFiyatController.text.trim().isNotEmpty
                      ? _parseDecimal(birimFiyatController.text)
                      : null;

                  // İplik stok kaydı ekle
                  final stokData = {
                    'ad': adController.text.trim(),
                    'renk': renkController.text.trim().isNotEmpty
                        ? renkController.text.trim()
                        : null,
                    'lot_no': lotController.text.trim().isNotEmpty
                        ? lotController.text.trim()
                        : null,
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

                  try {
                    await _stokHareketiKaydet(
                      stokData: stokData,
                      hareketTipi: 'giris',
                      miktar: miktar,
                      aciklama: 'İlk stok girişi',
                    );
                  } catch (rpcError) {
                    debugPrint(
                        'İplik stok RPC kullanılamadı, klasik kayıt deneniyor: $rpcError');
                    final stokResponse = await supabase
                        .from(DbTables.iplikStoklari)
                        .insert(stokData)
                        .select('id')
                        .single();

                    await supabase.from(DbTables.iplikHareketleri).insert({
                      'iplik_id': stokResponse['id'],
                      'hareket_tipi': 'giris',
                      'miktar': miktar,
                      'aciklama': 'İlk stok girişi',
                      'firma_id': TenantManager.instance.requireFirmaId,
                    });
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    await _verileriYukle();
                    if (!context.mounted) return;
                    context.showSuccessSnackBar(
                        'İplik girişi başarıyla kaydedildi');
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
      final firmaId = TenantManager.instance.requireFirmaId;
      final modelVeri = await supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, ana_renkler, toplam_adet, adet')
          .eq('firma_id', firmaId)
          .or('tamamlandi.is.null,tamamlandi.eq.false')
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
                        Text("İplik: ${stok['ad']}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Renk: ${stok['renk'] ?? '-'}"),
                        Text('Lot: ${stok['lot_no'] ?? '-'}'),
                        Text(
                            "Mevcut Miktar: ${stok['miktar']} ${stok['birim'] ?? 'kg'}"),
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
                    DropdownMenuItem(
                        value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(
                        value: 'sayim', child: Text('Sayım Düzeltmesi')),
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
                      final renk = model['renk'] ?? model['ana_renkler'] ?? '-';
                      return DropdownMenuItem(
                        value: model,
                        child: Text(
                            '${model['marka']} ${model['item_no']} - $renk'),
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
                  final miktar = _parseDecimal(miktarController.text);
                  if (miktar == null || miktar <= 0) {
                    throw 'Geçerli bir miktar giriniz';
                  }

                  final mevcutMiktar = (stok['miktar'] as num).toDouble();
                  if (hareketTipi != 'sayim' && miktar > mevcutMiktar) {
                    throw 'Yetersiz stok miktarı. Mevcut: $mevcutMiktar kg';
                  }

                  double yeniMiktar;
                  if (hareketTipi == 'sayim') {
                    yeniMiktar =
                        miktar; // Sayım düzeltmesinde miktar direkt olarak ayarlanır
                  } else {
                    yeniMiktar = mevcutMiktar - miktar;
                  }

                  final aciklama = aciklamaController.text.trim().isNotEmpty
                      ? aciklamaController.text.trim()
                      : null;

                  try {
                    await _stokHareketiKaydet(
                      iplikId: stok['id']?.toString(),
                      hareketTipi: hareketTipi,
                      miktar: miktar,
                      aciklama: aciklama,
                      modelId: seciliModel?['id']?.toString(),
                    );
                  } catch (rpcError) {
                    debugPrint(
                        'İplik stok RPC kullanılamadı, klasik hareket deneniyor: $rpcError');
                    // Stok miktarını güncelle
                    await supabase
                        .from(DbTables.iplikStoklari)
                        .update({
                          'miktar': yeniMiktar,
                          'toplam_deger': stok['birim_fiyat'] != null
                              ? yeniMiktar *
                                  (stok['birim_fiyat'] as num).toDouble()
                              : null,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', stok['id'])
                        .eq('firma_id', TenantManager.instance.requireFirmaId);

                    // Hareket kaydı ekle
                    await supabase.from(DbTables.iplikHareketleri).insert({
                      'iplik_id': stok['id'],
                      'hareket_tipi': hareketTipi,
                      'miktar': miktar,
                      'aciklama': aciklama,
                      'model_id': seciliModel?['id'],
                      'firma_id': TenantManager.instance.requireFirmaId,
                    });
                  }

                  if (yeniMiktar <= 10) {
                    await BildirimService().stokKritikUyarisi(
                      stokAdi: stok['ad']?.toString() ?? 'İplik stoğu',
                      mevcutMiktar: yeniMiktar,
                      kritikSeviye: 10,
                      birim: stok['birim']?.toString() ?? 'kg',
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    await _verileriYukle();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${stok['ad']} için $miktar kg $hareketTipi kaydedildi'),
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
    final miktarController =
        TextEditingController(text: stok['miktar'].toString());
    final birimFiyatController =
        TextEditingController(text: stok['birim_fiyat']?.toString() ?? '');
    Map<String, dynamic>? seciliTedarikci =
        tedarikciler.where((t) => t['id'] == stok['tedarikci_id']).isNotEmpty
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
                if (adController.text.trim().isEmpty ||
                    miktarController.text.trim().isEmpty) {
                  throw 'İplik adı ve miktar zorunludur';
                }

                final miktar = _parseDecimal(miktarController.text);
                if (miktar == null || miktar < 0) {
                  throw 'Geçerli bir miktar girin';
                }

                final birimFiyat = birimFiyatController.text.trim().isNotEmpty
                    ? _parseDecimal(birimFiyatController.text)
                    : null;
                final eskiMiktar = (stok['miktar'] as num?)?.toDouble() ?? 0.0;
                final miktarDegisti = (miktar - eskiMiktar).abs() > 0.0001;

                final updateData = {
                  'ad': adController.text.trim(),
                  'renk': renkController.text.trim().isNotEmpty
                      ? renkController.text.trim()
                      : null,
                  'lot_no': lotController.text.trim().isNotEmpty
                      ? lotController.text.trim()
                      : null,
                  'birim_fiyat': birimFiyat,
                  'toplam_deger':
                      birimFiyat != null ? eskiMiktar * birimFiyat : null,
                  'tedarikci_id': seciliTedarikci?['id'],
                  'updated_at': DateTime.now().toIso8601String(),
                };

                await supabase
                    .from(DbTables.iplikStoklari)
                    .update(updateData)
                    .eq('id', stok['id'])
                    .eq('firma_id', TenantManager.instance.requireFirmaId);

                if (miktarDegisti) {
                  try {
                    await _stokHareketiKaydet(
                      iplikId: stok['id']?.toString(),
                      hareketTipi: 'sayim',
                      miktar: miktar,
                      aciklama:
                          'Stok düzenleme sayım düzeltmesi: ${eskiMiktar.toStringAsFixed(2)} kg -> ${miktar.toStringAsFixed(2)} kg',
                    );
                  } catch (rpcError) {
                    debugPrint(
                        'İplik stok RPC kullanılamadı, klasik sayım deneniyor: $rpcError');
                    await supabase
                        .from(DbTables.iplikStoklari)
                        .update({
                          'miktar': miktar,
                          'toplam_deger':
                              birimFiyat != null ? miktar * birimFiyat : null,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', stok['id'])
                        .eq('firma_id', TenantManager.instance.requireFirmaId);
                    await supabase.from(DbTables.iplikHareketleri).insert({
                      'iplik_id': stok['id'],
                      'hareket_tipi': 'sayim',
                      'miktar': miktar,
                      'aciklama':
                          'Stok düzenleme sayım düzeltmesi: ${eskiMiktar.toStringAsFixed(2)} kg -> ${miktar.toStringAsFixed(2)} kg',
                      'firma_id': TenantManager.instance.requireFirmaId,
                    });
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  await _verileriYukle();
                  if (!context.mounted) return;
                  context
                      .showSuccessSnackBar('İplik stoku başarıyla güncellendi');
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
          content: Text(
              '${stok['ad']} - ${stok['renk'] ?? 'Renk Yok'} ipliğini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'),
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

  Future<void> _stokBirlestirmeDialogGoster() async {
    final gruplar = _birlestirilebilirStokGruplari();
    if (gruplar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Birleştirilecek aynı iplik, renk, lot ve tedarikçi grubu yok',
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İplik Stoklarını Birleştir'),
        content: SizedBox(
          width: 620,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: gruplar.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final grup = gruplar[index];
              final ilk = grup.first;
              final toplam = grup.fold<double>(
                0,
                (sum, stok) =>
                    sum + ((stok['miktar'] as num?)?.toDouble() ?? 0),
              );
              return ListTile(
                leading: const Icon(Icons.merge_type),
                title: Text(
                  '${ilk['ad'] ?? '-'} / ${ilk['renk'] ?? '-'} / Lot: ${ilk['lot_no'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${grup.length} satır, toplam ${toplam.toStringAsFixed(2)} ${ilk['birim'] ?? 'kg'} - ${_tedarikciAdi(ilk)}',
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _stokGrubunuBirlestir(grup);
                  },
                  child: const Text('Birleştir'),
                ),
              );
            },
          ),
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

  List<List<Map<String, dynamic>>> _birlestirilebilirStokGruplari() {
    final gruplar = <String, List<Map<String, dynamic>>>{};
    for (final stok in iplikStoklari) {
      final key = _stokBirlestirmeAnahtari(stok);
      gruplar.putIfAbsent(key, () => []).add(stok);
    }
    return gruplar.values.where((grup) => grup.length > 1).map((grup) {
      final sirali = List<Map<String, dynamic>>.from(grup);
      sirali.sort((a, b) => (a['created_at'] ?? '').toString().compareTo(
            (b['created_at'] ?? '').toString(),
          ));
      return sirali;
    }).toList();
  }

  String _stokBirlestirmeAnahtari(Map<String, dynamic> stok) {
    String norm(dynamic value) =>
        (value ?? '').toString().trim().toLowerCase().replaceAll('İ', 'i');
    return [
      norm(stok['ad']),
      norm(stok['renk']),
      norm(stok['lot_no']),
      norm(stok['tedarikci_id']),
    ].join('|');
  }

  Future<void> _stokGrubunuBirlestir(List<Map<String, dynamic>> grup) async {
    if (grup.length < 2) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Birleştirme Onayı'),
        content: Text(
          '${grup.length} stok satırı tek satırda birleştirilecek. Hareketler ana stok kaydına taşınacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Birleştir'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      final anaStok = grup.first;
      final digerStoklar = grup.skip(1).toList();
      final toplamMiktar = grup.fold<double>(
        0,
        (sum, stok) => sum + ((stok['miktar'] as num?)?.toDouble() ?? 0),
      );
      final fiyatliSatirlar =
          grup.where((stok) => stok['birim_fiyat'] != null).toList();
      final fiyatSatiri =
          fiyatliSatirlar.isNotEmpty ? fiyatliSatirlar.last : anaStok;
      final birimFiyat = (fiyatSatiri['birim_fiyat'] as num?)?.toDouble();

      await supabase
          .from(DbTables.iplikStoklari)
          .update({
            'miktar': toplamMiktar,
            'birim': anaStok['birim'] ?? 'kg',
            'birim_fiyat': birimFiyat,
            'para_birimi': fiyatSatiri['para_birimi'] ?? anaStok['para_birimi'],
            'toplam_deger':
                birimFiyat != null ? toplamMiktar * birimFiyat : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', anaStok['id'])
          .eq('firma_id', firmaId);

      for (final stok in digerStoklar) {
        await supabase
            .from(DbTables.iplikHareketleri)
            .update({'iplik_id': anaStok['id']})
            .eq('iplik_id', stok['id'])
            .eq('firma_id', firmaId);
        await supabase
            .from(DbTables.iplikStoklari)
            .delete()
            .eq('id', stok['id'])
            .eq('firma_id', firmaId);
      }

      await _verileriYukle();
      if (mounted) {
        context.showSuccessSnackBar('Stok satırları birleştirildi');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Birleştirme hatası: $e');
    }
  }

  Future<void> exportToExcel(List<Map<String, dynamic>> data,
      {required String fileName}) async {
    try {
      final isHareketExport = fileName.toLowerCase().contains('hareket');
      final exportData = isHareketExport
          ? data.map((kayit) {
              final iplik = kayit['iplik'] is Map
                  ? Map<String, dynamic>.from(kayit['iplik'])
                  : <String, dynamic>{};
              Map<String, dynamic> stok = iplik;
              if (stok.isEmpty) {
                for (final mevcutStok in iplikStoklari) {
                  if (mevcutStok['id'] == kayit['iplik_id']) {
                    stok = mevcutStok;
                    break;
                  }
                }
              }
              return {
                ...kayit,
                'iplik_ad': stok['ad'] ?? '',
                'renk': stok['renk'] ?? '',
                'lot_no': stok['lot_no'] ?? '',
                'birim': stok['birim'] ?? 'kg',
                'hareket': _getHareketBaslik(kayit['hareket_tipi'] ?? ''),
              };
            }).toList()
          : data.map((stok) {
              return {
                ...stok,
                'tedarikci_adi': _tedarikciAdi(stok),
                'durum':
                    _stokDurumBilgisi((stok['miktar'] as num?)?.toDouble() ?? 0)
                        .$1,
              };
            }).toList();

      await ExcelHelper.exportToExcel(
        data: exportData,
        fileName: fileName,
        columns: isHareketExport
            ? {
                'created_at': 'Tarih',
                'iplik_ad': 'İplik Adı',
                'renk': 'Renk',
                'lot_no': 'Lot No',
                'hareket': 'Hareket',
                'miktar': 'Miktar',
                'birim': 'Birim',
                'aciklama': 'Açıklama',
                'model_id': 'Model ID',
              }
            : {
                'ad': 'İplik Adı',
                'renk': 'Renk',
                'lot_no': 'Lot No',
                'miktar': 'Miktar',
                'birim': 'Birim',
                'durum': 'Durum',
                'tedarikci_adi': 'Tedarikçi',
                'birim_fiyat': 'Birim Fiyat',
                'para_birimi': 'Para Birimi',
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
