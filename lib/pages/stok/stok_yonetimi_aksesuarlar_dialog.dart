// ignore_for_file: invalid_use_of_protected_member
part of 'stok_yonetimi_aksesuarlar_coklu_beden.dart';

class _TopluSarfSatiri {
  _TopluSarfSatiri(this.aksesuar) {
    bedenSatirlari.add(_TopluSarfBedenSatiri());
  }

  final Map<String, dynamic> aksesuar;
  final List<_TopluSarfBedenSatiri> bedenSatirlari = [];
  bool secili = false;

  List<Map<String, dynamic>> get bedenler => List<Map<String, dynamic>>.from(
        (aksesuar['aksesuar_bedenler'] as List? ?? const [])
            .where((beden) => beden['durum'] == 'aktif'),
      );

  void bedenSatiriEkle() => bedenSatirlari.add(_TopluSarfBedenSatiri());

  void bedenSatiriSil(_TopluSarfBedenSatiri satir) {
    if (bedenSatirlari.length <= 1) return;
    bedenSatirlari.remove(satir);
    satir.dispose();
  }

  void temizle() {
    for (final satir in bedenSatirlari) {
      satir.dispose();
    }
    bedenSatirlari
      ..clear()
      ..add(_TopluSarfBedenSatiri());
  }

  void dispose() {
    for (final satir in bedenSatirlari) {
      satir.dispose();
    }
  }
}

class _TopluSarfBedenSatiri {
  final TextEditingController adetController = TextEditingController();
  Map<String, dynamic>? seciliBeden;

  void dispose() => adetController.dispose();
}

/// Stok yonetimi aksesuarlar - dialog metotlari
extension _DialogExt on _StokYonetimiAksesuarlarCokluBedenState {
  void _showAddEditDialog({Map<String, dynamic>? aksesuar}) {
    final isEdit = aksesuar != null;

    // Form controllers
    final skuController = TextEditingController(text: aksesuar?['sku'] ?? '');
    final adController = TextEditingController(text: aksesuar?['ad'] ?? '');
    final markaController =
        TextEditingController(text: aksesuar?['marka'] ?? '');
    final renkController = TextEditingController(text: aksesuar?['renk'] ?? '');
    final renkKoduController =
        TextEditingController(text: aksesuar?['renk_kodu'] ?? '');
    final birimController =
        TextEditingController(text: aksesuar?['birim'] ?? 'adet');
    final birimFiyatController =
        TextEditingController(text: aksesuar?['birim_fiyat']?.toString() ?? '');
    final malzemeController =
        TextEditingController(text: aksesuar?['malzeme'] ?? '');
    final aciklamaController =
        TextEditingController(text: aksesuar?['aciklama'] ?? '');
    final minimumStokController = TextEditingController(
        text: aksesuar?['minimum_stok']?.toString() ?? '10');
    int? seciliTedarikciId =
        int.tryParse(aksesuar?['tedarikci_id']?.toString() ?? '');

    // Beden listesi
    final List<Map<String, dynamic>> bedenListesi = [];

    // Mevcut aksesuarın bedenlerini yükle
    if (isEdit && aksesuar['aksesuar_bedenler'] != null) {
      for (var beden in aksesuar['aksesuar_bedenler']) {
        if (beden['durum'] == 'aktif') {
          bedenListesi.add({
            'id': beden['id'],
            'beden': beden['beden'],
            'stok_miktari': beden['stok_miktari'],
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Aksesuar Güncelle' : 'Yeni Aksesuar Ekle'),
        content: StatefulBuilder(
          builder: (context, setStateModal) => SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Temel bilgiler
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU Kodu *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: adController,
                          decoration: const InputDecoration(
                            labelText: 'Aksesuar Adı *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: markaController,
                          decoration: const InputDecoration(
                            labelText: 'Marka',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: malzemeController,
                          decoration: const InputDecoration(
                            labelText: 'Malzeme',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: renkController,
                          decoration: const InputDecoration(
                            labelText: 'Renk',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: renkKoduController,
                          decoration: const InputDecoration(
                            labelText: 'Renk Kodu',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: birimController,
                          decoration: const InputDecoration(
                            labelText: 'Birim',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: birimFiyatController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Birim Fiyat (TL)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: minimumStokController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Stok Uyarısı',
                      border: OutlineInputBorder(),
                      helperText:
                          'Toplam stok bu değerin altına düştüğünde uyarı verilir',
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int?>(
                    initialValue: seciliTedarikciId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Varsayılan Tedarikçi (Opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tedarikçi seçilmedi'),
                      ),
                      ..._tedarikciler
                          .map((tedarikci) => DropdownMenuItem<int?>(
                                value: int.tryParse(tedarikci['id'].toString()),
                                child: Text(
                                  _tedarikciEtiketi(tedarikci),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                    ],
                    onChanged: (value) =>
                        setStateModal(() => seciliTedarikciId = value),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: aciklamaController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (Opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Beden-Stok Yönetimi
                  const Text(
                    'Beden ve Stok Yönetimi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Mevcut bedenler listesi
                  if (bedenListesi.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: bedenListesi.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> beden = entry.value;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.white
                                  : Colors.grey.shade50,
                              border: index > 0
                                  ? Border(
                                      top: BorderSide(
                                          color: Colors.grey.shade300))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Beden: ${beden['beden']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Stok: ${beden['stok_miktari']} adet',
                                        style: TextStyle(
                                          color: beden['stok_miktari'] > 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _showBedenDuzenleDialog(
                                      index,
                                      beden,
                                      setStateModal,
                                      bedenListesi),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    setStateModal(() {
                                      bedenListesi.removeAt(index);
                                    });
                                  },
                                  tooltip: 'Sil',
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Yeni beden ekleme butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showBedenEklemeDialog(setStateModal, bedenListesi),
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Beden Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  if (bedenListesi.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ En az bir beden eklemek zorunludur',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _saveAksesuar(
              context,
              isEdit,
              aksesuar?['id'],
              skuController,
              adController,
              markaController,
              renkController,
              renkKoduController,
              birimController,
              birimFiyatController,
              malzemeController,
              aciklamaController,
              minimumStokController,
              seciliTedarikciId,
              bedenListesi,
            ),
            child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showBedenEklemeDialog(
      StateSetter setStateModal, List<Map<String, dynamic>> bedenListesi) {
    final TextEditingController bedenController = TextEditingController();
    final TextEditingController stokController =
        TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Beden Ekle'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bedenController,
                decoration: const InputDecoration(
                  labelText: 'Beden',
                  hintText: 'Örn: S, M, L, XL, 75cm, 18mm, 2.5m',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Başlangıç Stok Miktarı',
                  border: OutlineInputBorder(),
                  suffix: Text('adet'),
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
            onPressed: () {
              if (bedenController.text.trim().isNotEmpty) {
                // Aynı beden var mı kontrol et
                final bool bedenMevcut = bedenListesi.any((b) =>
                    b['beden'].toString().toLowerCase() ==
                    bedenController.text.trim().toLowerCase());

                if (bedenMevcut) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu beden zaten eklenmiş'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setStateModal(() {
                  bedenListesi.add({
                    'beden': bedenController.text.trim(),
                    'stok_miktari': int.tryParse(stokController.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showBedenDuzenleDialog(int index, Map<String, dynamic> beden,
      StateSetter setStateModal, List<Map<String, dynamic>> bedenListesi) {
    final TextEditingController bedenController =
        TextEditingController(text: beden['beden']);
    final TextEditingController stokController =
        TextEditingController(text: beden['stok_miktari'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beden Düzenle'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bedenController,
                decoration: const InputDecoration(
                  labelText: 'Beden',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok Miktarı',
                  border: OutlineInputBorder(),
                  suffix: Text('adet'),
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
            onPressed: () {
              if (bedenController.text.trim().isNotEmpty) {
                setStateModal(() {
                  bedenListesi[index] = {
                    ...beden,
                    'beden': bedenController.text.trim(),
                    'stok_miktari': int.tryParse(stokController.text) ?? 0,
                  };
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAksesuar(
    BuildContext context,
    bool isEdit,
    String? aksesuarId,
    TextEditingController skuController,
    TextEditingController adController,
    TextEditingController markaController,
    TextEditingController renkController,
    TextEditingController renkKoduController,
    TextEditingController birimController,
    TextEditingController birimFiyatController,
    TextEditingController malzemeController,
    TextEditingController aciklamaController,
    TextEditingController minimumStokController,
    int? tedarikciId,
    List<Map<String, dynamic>> bedenListesi,
  ) async {
    if (skuController.text.trim().isEmpty || adController.text.trim().isEmpty) {
      context.showSnackBar('SKU ve Aksesuar adı gerekli');
      return;
    }

    if (bedenListesi.isEmpty) {
      context.showSnackBar('En az bir beden eklemek zorunludur');
      return;
    }

    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      // 1. Ana aksesuar kaydını oluştur/güncelle
      final aksesuarData = {
        'sku': skuController.text.trim(),
        'ad': adController.text.trim(),
        'marka': markaController.text.trim().isNotEmpty
            ? markaController.text.trim()
            : null,
        'renk': renkController.text.trim().isNotEmpty
            ? renkController.text.trim()
            : null,
        'renk_kodu': renkKoduController.text.trim().isNotEmpty
            ? renkKoduController.text.trim()
            : null,
        'birim': birimController.text.trim().isNotEmpty
            ? birimController.text.trim()
            : 'adet',
        'birim_fiyat':
            double.tryParse(birimFiyatController.text.replaceAll(',', '.')) ??
                0.0,
        'malzeme': malzemeController.text.trim().isNotEmpty
            ? malzemeController.text.trim()
            : null,
        'aciklama': aciklamaController.text.trim().isNotEmpty
            ? aciklamaController.text.trim()
            : null,
        'minimum_stok': int.tryParse(minimumStokController.text) ?? 10,
        'tedarikci_id': tedarikciId,
        'durum': 'aktif',
        'updated_at': DateTime.now().toIso8601String(),
        if (!isEdit) 'firma_id': firmaId,
      };

      debugPrint('📝 Aksesuar kayıt verisi: $aksesuarData');
      debugPrint(
          '💰 Birim Fiyat Controller değeri: "${birimFiyatController.text}"');
      debugPrint(
          '💰 Birim Fiyat parse edilmiş: ${aksesuarData['birim_fiyat']}');

      String finalAksesuarId;

      if (isEdit && aksesuarId != null) {
        // Güncelleme
        debugPrint('🔄 Aksesuar güncelleniyor: $aksesuarId');
        final updateResult = await supabase
            .from(DbTables.aksesuarlar)
            .update(aksesuarData)
            .eq('firma_id', firmaId)
            .eq('id', aksesuarId)
            .select()
            .single();
        finalAksesuarId = aksesuarId;
        debugPrint('✅ Aksesuar güncellendi: $updateResult');

        // Mevcut bedenlerini pasif yap
        await supabase
            .from(DbTables.aksesuarBedenler)
            .update({'durum': 'pasif'})
            .eq('firma_id', firmaId)
            .eq('aksesuar_id', aksesuarId);
        debugPrint('✅ Eski bedenler pasif yapıldı');
      } else {
        // Yeni kayıt
        debugPrint('➕ Yeni aksesuar ekleniyor...');
        final result = await supabase
            .from(DbTables.aksesuarlar)
            .insert(aksesuarData)
            .select('id')
            .single();
        finalAksesuarId = result['id'];
        debugPrint('✅ Yeni aksesuar eklendi: $finalAksesuarId');
      }

      // 2. Beden kayıtlarını ekle/güncelle (upsert mantığı ile)
      debugPrint('📦 Beden kayıtları işleniyor: ${bedenListesi.length} adet');
      int toplamStok = 0;

      for (var beden in bedenListesi) {
        final bedenAdi = beden['beden'];
        final stokMiktari = beden['stok_miktari'] as int? ?? 0;
        toplamStok += stokMiktari;

        // Önce bu aksesuar+beden kombinasyonunun var olup olmadığını kontrol et
        final mevcutBeden = await supabase
            .from(DbTables.aksesuarBedenler)
            .select('id')
            .eq('firma_id', firmaId)
            .eq('aksesuar_id', finalAksesuarId)
            .eq('beden', bedenAdi)
            .maybeSingle();

        if (mevcutBeden != null) {
          // Mevcut bedeni güncelle
          await supabase
              .from(DbTables.aksesuarBedenler)
              .update({
                'stok_miktari': stokMiktari,
                'durum': 'aktif',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('firma_id', firmaId)
              .eq('id', mevcutBeden['id']);
          debugPrint('  ✅ Beden güncellendi: $bedenAdi (stok: $stokMiktari)');
        } else {
          // Yeni beden ekle
          await supabase.from(DbTables.aksesuarBedenler).insert({
            'aksesuar_id': finalAksesuarId,
            'beden': bedenAdi,
            'stok_miktari': stokMiktari,
            'durum': 'aktif',
            'firma_id': firmaId,
          });
          debugPrint('  ✅ Yeni beden eklendi: $bedenAdi (stok: $stokMiktari)');
        }
      }

      // 3. Ana aksesuar tablosundaki toplam miktar alanını güncelle
      await supabase
          .from(DbTables.aksesuarlar)
          .update({
            'miktar': toplamStok,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', firmaId)
          .eq('id', finalAksesuarId);
      debugPrint('📊 Toplam stok güncellendi: $toplamStok');

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Aksesuar başarıyla güncellendi'
              : 'Aksesuar başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadAksesuarlar();
    } catch (e, stackTrace) {
      debugPrint('❌ Aksesuar kaydetme hatası: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  int _getTotalStock(Map<String, dynamic> aksesuar) {
    if (aksesuar['aksesuar_bedenler'] == null) return 0;

    int total = 0;
    for (var beden in aksesuar['aksesuar_bedenler']) {
      if (beden['durum'] == 'aktif') {
        total += (beden['stok_miktari'] as int? ?? 0);
      }
    }
    return total;
  }

  // ==================== SARF DİALOG ====================
  Future<void> _showTopluSarfDialog() async {
    final firmaId = TenantManager.instance.requireFirmaId;
    final modelIds = _modelKullanimlari.values
        .expand((kullanimlar) => kullanimlar)
        .map((kullanim) => kullanim['model_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (modelIds.isEmpty) {
      context.showErrorSnackBar(
        'Modele tanımlanmış aktif aksesuar bulunmuyor',
      );
      return;
    }

    try {
      final sonuclar = await Future.wait([
        supabase
            .from(DbTables.trikoTakip)
            .select('id, item_no, marka, model_adi')
            .eq('firma_id', firmaId)
            .inFilter('id', modelIds)
            .order('item_no'),
        supabase
            .from(DbTables.tedarikciler)
            .select('id, ad, sirket')
            .eq('firma_id', firmaId)
            .order('sirket'),
      ]);
      if (!mounted) return;

      final modeller = List<Map<String, dynamic>>.from(sonuclar[0]);
      final tedarikciler = List<Map<String, dynamic>>.from(sonuclar[1]);
      final aciklamaController = TextEditingController();
      Map<String, dynamic>? seciliModel;
      Map<String, dynamic>? seciliTedarikci;
      List<_TopluSarfSatiri> satirlar = [];
      var kaydediliyor = false;

      void satirlariTemizle() {
        for (final satir in satirlar) {
          satir.dispose();
        }
        satirlar = [];
      }

      String modelEtiketi(Map<String, dynamic> model) => [
            model['marka']?.toString() ?? '',
            model['item_no']?.toString() ?? '',
            model['model_adi']?.toString() ?? '',
          ].where((deger) => deger.trim().isNotEmpty).join(' - ');

      String tedarikciEtiketi(Map<String, dynamic> tedarikci) {
        final sirket = tedarikci['sirket']?.toString().trim() ?? '';
        return sirket.isNotEmpty
            ? sirket
            : tedarikci['ad']?.toString().trim() ?? '';
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> kaydet() async {
              if (seciliModel == null) {
                ctx.showErrorSnackBar('Model seçiniz');
                return;
              }
              if (seciliTedarikci == null) {
                ctx.showErrorSnackBar('Tedarikçi seçiniz');
                return;
              }

              final seciliSatirlar =
                  satirlar.where((satir) => satir.secili).toList();
              if (seciliSatirlar.isEmpty) {
                ctx.showErrorSnackBar('En az bir aksesuar seçiniz');
                return;
              }

              final bedenIdleri = <String>{};
              final rpcSatirlari = <Map<String, dynamic>>[];
              for (final satir in seciliSatirlar) {
                for (final bedenSatiri in satir.bedenSatirlari) {
                  final beden = bedenSatiri.seciliBeden;
                  if (beden == null) {
                    ctx.showErrorSnackBar(
                      '${satir.aksesuar['ad']} için beden seçiniz',
                    );
                    return;
                  }
                  final bedenId = beden['id']?.toString() ?? '';
                  if (bedenId.isEmpty || !bedenIdleri.add(bedenId)) {
                    ctx.showErrorSnackBar(
                      'Aynı aksesuar bedeni birden fazla seçilemez',
                    );
                    return;
                  }
                  final miktar = int.tryParse(
                    bedenSatiri.adetController.text.trim(),
                  );
                  final stok = (beden['stok_miktari'] as num?)?.toInt() ?? 0;
                  if (miktar == null || miktar <= 0) {
                    ctx.showErrorSnackBar(
                      '${satir.aksesuar['ad']} için geçerli adet giriniz',
                    );
                    return;
                  }
                  if (miktar > stok) {
                    ctx.showErrorSnackBar(
                      '${satir.aksesuar['ad']} - ${beden['beden']} için stok '
                      'yetersiz (Mevcut: $stok)',
                    );
                    return;
                  }
                  rpcSatirlari.add({
                    'aksesuar_id': satir.aksesuar['id'].toString(),
                    'aksesuar_beden_id': bedenId,
                    'miktar': miktar,
                  });
                }
              }

              setStateDialog(() => kaydediliyor = true);
              try {
                await supabase.rpc(
                  'aksesuar_toplu_sarf_kaydet',
                  params: {
                    'p_firma_id': firmaId,
                    'p_model_id': seciliModel!['id'].toString(),
                    'p_tedarikci_adi': tedarikciEtiketi(seciliTedarikci!),
                    'p_aciklama': aciklamaController.text.trim(),
                    'p_satirlar': rpcSatirlari,
                  },
                );

                for (final satir in seciliSatirlar) {
                  for (final bedenSatiri in satir.bedenSatirlari) {
                    final beden = bedenSatiri.seciliBeden!;
                    final miktar =
                        int.parse(bedenSatiri.adetController.text.trim());
                    final kalan =
                        ((beden['stok_miktari'] as num?)?.toInt() ?? 0) -
                            miktar;
                    final minimumStok =
                        (satir.aksesuar['minimum_stok'] as num?)?.toDouble() ??
                            10;
                    if (kalan <= minimumStok) {
                      try {
                        await BildirimService().stokKritikUyarisi(
                          stokAdi:
                              '${satir.aksesuar['ad']} - ${beden['beden']}',
                          mevcutMiktar: kalan.toDouble(),
                          kritikSeviye: minimumStok,
                          birim: 'adet',
                        );
                      } catch (e) {
                        debugPrint('Kritik stok bildirimi oluşturulamadı: $e');
                      }
                    }
                  }
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                context.showSuccessSnackBar(
                  '${rpcSatirlari.length} beden satırı için toplu sarf yapıldı',
                );
                await _loadAksesuarlar();
                await _loadSarfKayitlari();
              } catch (e) {
                if (!ctx.mounted) return;
                setStateDialog(() => kaydediliyor = false);
                ctx.showErrorSnackBar('Toplu sarf hatası: $e');
              }
            }

            Widget sarfSatiri(_TopluSarfSatiri satir) {
              final stokVar = satir.bedenler.any(
                (beden) => ((beden['stok_miktari'] as num?)?.toInt() ?? 0) > 0,
              );
              final kullanilabilirBedenSayisi = satir.bedenler
                  .where(
                    (beden) =>
                        ((beden['stok_miktari'] as num?)?.toInt() ?? 0) > 0,
                  )
                  .length;
              final stokYetersiz = satir.secili &&
                  satir.bedenSatirlari.any((bedenSatiri) {
                    final mevcutStok =
                        (bedenSatiri.seciliBeden?['stok_miktari'] as num?)
                                ?.toInt() ??
                            0;
                    final girilen = int.tryParse(
                          bedenSatiri.adetController.text.trim(),
                        ) ??
                        0;
                    return bedenSatiri.seciliBeden != null &&
                        girilen > mevcutStok;
                  });

              final aksesuarBilgisi = Row(
                children: [
                  Checkbox(
                    value: satir.secili,
                    onChanged: stokVar && !kaydediliyor
                        ? (deger) => setStateDialog(() {
                              satir.secili = deger ?? false;
                              if (!satir.secili) {
                                satir.temizle();
                              }
                            })
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          satir.aksesuar['ad']?.toString() ??
                              'İsimsiz aksesuar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'SKU: ${satir.aksesuar['sku'] ?? '-'} | Renk: ${satir.aksesuar['renk'] ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              Widget bedenGirisSatiri(
                _TopluSarfBedenSatiri bedenSatiri,
                int index,
              ) {
                final seciliBedenIdleri = satir.bedenSatirlari
                    .where((diger) => !identical(diger, bedenSatiri))
                    .map((diger) => diger.seciliBeden?['id']?.toString())
                    .whereType<String>()
                    .toSet();
                final mevcutStok =
                    (bedenSatiri.seciliBeden?['stok_miktari'] as num?)
                            ?.toInt() ??
                        0;
                final girilen = int.tryParse(
                      bedenSatiri.adetController.text.trim(),
                    ) ??
                    0;
                final buSatirdaStokYetersiz =
                    bedenSatiri.seciliBeden != null && girilen > mevcutStok;

                final bedenAlani =
                    DropdownButtonFormField<Map<String, dynamic>>(
                  key: ValueKey(
                    'toplu-sarf-${satir.aksesuar['id']}-$index-${bedenSatiri.seciliBeden?['id']}',
                  ),
                  // ignore: deprecated_member_use
                  value: bedenSatiri.seciliBeden,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Beden / Ölçü ${index + 1}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: satir.bedenler.map((beden) {
                    final bedenId = beden['id']?.toString();
                    final stok = (beden['stok_miktari'] as num?)?.toInt() ?? 0;
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: beden,
                      enabled: stok > 0 && !seciliBedenIdleri.contains(bedenId),
                      child: Text(
                        '${beden['beden']} (Stok: $stok)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: satir.secili && !kaydediliyor
                      ? (beden) => setStateDialog(() {
                            bedenSatiri.seciliBeden = beden;
                          })
                      : null,
                );
                final adetAlani = TextField(
                  controller: bedenSatiri.adetController,
                  enabled: satir.secili && !kaydediliyor,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setStateDialog(() {}),
                  decoration: InputDecoration(
                    labelText: 'Sarf Adedi',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    helperText: bedenSatiri.seciliBeden == null
                        ? null
                        : 'Mevcut: $mevcutStok',
                    errorText: buSatirdaStokYetersiz ? 'Stok yetersiz' : null,
                  ),
                );
                final silButonu = IconButton(
                  onPressed: !kaydediliyor && satir.bedenSatirlari.length > 1
                      ? () => setStateDialog(
                            () => satir.bedenSatiriSil(bedenSatiri),
                          )
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Beden satırını kaldır',
                  color: _StokYonetimiAksesuarlarCokluBedenState._dangerColor,
                );

                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 540) {
                        return Column(
                          children: [
                            bedenAlani,
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: adetAlani),
                                const SizedBox(width: 4),
                                silButonu,
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: bedenAlani),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: adetAlani),
                          const SizedBox(width: 4),
                          silButonu,
                        ],
                      );
                    },
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: satir.secili
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: stokYetersiz
                        ? _StokYonetimiAksesuarlarCokluBedenState._dangerColor
                        : satir.secili
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    aksesuarBilgisi,
                    if (!stokVar)
                      const Padding(
                        padding: EdgeInsets.only(left: 48, top: 4),
                        child: Text(
                          'Kullanılabilir stok bulunmuyor',
                          style: TextStyle(
                            color: _StokYonetimiAksesuarlarCokluBedenState
                                ._dangerColor,
                          ),
                        ),
                      ),
                    if (satir.secili) ...[
                      const Divider(height: 22),
                      ...satir.bedenSatirlari.indexed.map(
                        (entry) => bedenGirisSatiri(entry.$2, entry.$1),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: !kaydediliyor &&
                                  satir.bedenSatirlari.length <
                                      kullanilabilirBedenSayisi
                              ? () => setStateDialog(satir.bedenSatiriEkle)
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Beden Ekle'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.86,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
                        child: Row(
                          children: [
                            Icon(Icons.output_rounded,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Toplu Aksesuar Sarfı',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: kaydediliyor
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                              tooltip: 'Kapat',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final modelAlani = DropdownButtonFormField<
                                      Map<String, dynamic>>(
                                    // ignore: deprecated_member_use
                                    value: seciliModel,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Model *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: modeller
                                        .map(
                                          (model) => DropdownMenuItem<
                                              Map<String, dynamic>>(
                                            value: model,
                                            child: Text(
                                              modelEtiketi(model),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: kaydediliyor
                                        ? null
                                        : (model) => setStateDialog(() {
                                              satirlariTemizle();
                                              seciliModel = model;
                                              if (model == null) return;
                                              final modelId =
                                                  model['id'].toString();
                                              satirlar = aksesuarlar
                                                  .where((aksesuar) {
                                                    final aksesuarId =
                                                        aksesuar['id']
                                                            ?.toString();
                                                    return aksesuarId != null &&
                                                        (_modelKullanimlari[
                                                                    aksesuarId] ??
                                                                [])
                                                            .any((kullanim) =>
                                                                kullanim[
                                                                        'model_id']
                                                                    ?.toString() ==
                                                                modelId);
                                                  })
                                                  .map(_TopluSarfSatiri.new)
                                                  .toList();
                                            }),
                                  );
                                  final tedarikciAlani =
                                      DropdownButtonFormField<
                                          Map<String, dynamic>>(
                                    // ignore: deprecated_member_use
                                    value: seciliTedarikci,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Tedarikçi *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: tedarikciler
                                        .map(
                                          (tedarikci) => DropdownMenuItem<
                                              Map<String, dynamic>>(
                                            value: tedarikci,
                                            child: Text(
                                              tedarikciEtiketi(tedarikci),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: kaydediliyor
                                        ? null
                                        : (tedarikci) => setStateDialog(
                                              () => seciliTedarikci = tedarikci,
                                            ),
                                  );
                                  if (constraints.maxWidth < 620) {
                                    return Column(
                                      children: [
                                        modelAlani,
                                        const SizedBox(height: 12),
                                        tedarikciAlani,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: modelAlani),
                                      const SizedBox(width: 12),
                                      Expanded(child: tedarikciAlani),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: aciklamaController,
                                enabled: !kaydediliyor,
                                decoration: const InputDecoration(
                                  labelText: 'Açıklama (Opsiyonel)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              if (seciliModel == null)
                                const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: Text(
                                    'Aksesuarları listelemek için model seçiniz',
                                  ),
                                )
                              else if (satirlar.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: Text(
                                    'Bu modele tanımlanmış aktif aksesuar bulunmuyor',
                                  ),
                                )
                              else ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Aksesuarlar (${satirlar.where((s) => s.secili).length}/${satirlar.length})',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...satirlar.map(sarfSatiri),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: kaydediliyor
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text('İptal'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: kaydediliyor ? null : kaydet,
                              icon: kaydediliyor
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                kaydediliyor ? 'Kaydediliyor' : 'Toplu Sarf Et',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      satirlariTemizle();
      aciklamaController.dispose();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Toplu sarf ekranı açılamadı: $e');
    }
  }

  void _showSarfDialog(Map<String, dynamic> aksesuar) {
    final bedenler = (aksesuar['aksesuar_bedenler'] as List?)
            ?.where((b) =>
                b['durum'] == 'aktif' && (b['stok_miktari'] as int? ?? 0) > 0)
            .toList() ??
        [];

    if (bedenler.isEmpty) {
      context.showErrorSnackBar('Bu aksesuarın stokta bedeni yok');
      return;
    }

    final adetController = TextEditingController();
    final aciklamaController = TextEditingController();
    Map<String, dynamic>? seciliBeden =
        bedenler.length == 1 ? bedenler.first : null;
    Map<String, dynamic>? seciliFirma;
    List<Map<String, dynamic>> firmalar = [];
    bool firmaYukleniyor = true;

    Map<String, dynamic>? seciliModel;
    List<Map<String, dynamic>> modeller = [];
    bool modelYukleniyor = true;
    final aksesuarId = aksesuar['id']?.toString();
    final List<String> iliskiliModelIds = (aksesuarId != null
            ? (_modelKullanimlari[aksesuarId] ?? [])
                .map((k) => k['model_id']?.toString())
            : const Iterable<String?>.empty())
        .where((id) => id?.isNotEmpty ?? false)
        .cast<String>()
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          // Firmaları ve modelleri yükle (ilk açılışta)
          if (firmaYukleniyor) {
            firmaYukleniyor = false;
            final firmaId = TenantManager.instance.requireFirmaId;
            supabase
                .from(DbTables.tedarikciler)
                .select('id, ad, sirket, telefon')
                .eq('firma_id', firmaId)
                .order('sirket')
                .then((data) {
              if (ctx.mounted) {
                setStateDialog(() {
                  firmalar = List<Map<String, dynamic>>.from(data);
                });
              }
            }).catchError((e) {
              debugPrint('Firma yükleme hatası: $e');
            });
          }
          if (modelYukleniyor) {
            modelYukleniyor = false;
            if (iliskiliModelIds.isEmpty) {
              if (ctx.mounted) {
                setStateDialog(() {
                  modeller = [];
                });
              }
            } else {
              final firmaId = TenantManager.instance.requireFirmaId;
              supabase
                  .from(DbTables.trikoTakip)
                  .select('id, item_no, marka, model_adi')
                  .eq('firma_id', firmaId)
                  .inFilter('id', iliskiliModelIds)
                  .order('item_no')
                  .then((data) {
                if (ctx.mounted) {
                  setStateDialog(() {
                    modeller = List<Map<String, dynamic>>.from(data);
                  });
                }
              }).catchError((e) {
                debugPrint('Model yükleme hatası: $e');
              });
            }
          }

          final mevcutStok = (seciliBeden?['stok_miktari'] as int?) ?? 0;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.output_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('Sarf - ${aksesuar['ad']}')),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aksesuar bilgi
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${aksesuar['ad']} | SKU: ${aksesuar['sku'] ?? '-'} | Renk: ${aksesuar['renk'] ?? '-'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Beden seçimi
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: seciliBeden,
                      decoration: const InputDecoration(
                        labelText: 'Beden *',
                        border: OutlineInputBorder(),
                      ),
                      items: bedenler
                          .map((b) => DropdownMenuItem<Map<String, dynamic>>(
                                value: b,
                                child: Text(
                                    '${b['beden']}  (Stok: ${b['stok_miktari']})'),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setStateDialog(() => seciliBeden = val),
                    ),
                    const SizedBox(height: 12),

                    // Firma seçimi
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: seciliFirma,
                      decoration: const InputDecoration(
                        labelText: 'Tedarikçi *',
                        border: OutlineInputBorder(),
                      ),
                      items: firmalar.map((f) {
                        final label = f['sirket'] != null &&
                                f['sirket'].toString().isNotEmpty
                            ? f['sirket']
                            : '${f['ad'] ?? ''}'.trim();
                        return DropdownMenuItem<Map<String, dynamic>>(
                            value: f, child: Text(label));
                      }).toList(),
                      onChanged: (val) =>
                          setStateDialog(() => seciliFirma = val),
                    ),
                    const SizedBox(height: 12),

                    // Model seçimi
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: seciliModel,
                      decoration: const InputDecoration(
                        labelText: 'Model (Opsiyonel)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Sadece bu aksesuarın kullanıldığı modeller listelenir',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<Map<String, dynamic>>(
                          value: null,
                          child: Text('— Seçilmedi —',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ...modeller.map((m) {
                          final marka = m['marka']?.toString() ?? '';
                          final itemNo = m['item_no']?.toString() ?? '';
                          final label = [marka, itemNo]
                              .where((s) => s.isNotEmpty)
                              .join(' - ');
                          return DropdownMenuItem<Map<String, dynamic>>(
                              value: m, child: Text(label));
                        }),
                      ],
                      onChanged: (val) =>
                          setStateDialog(() => seciliModel = val),
                    ),
                    const SizedBox(height: 12),

                    // Adet
                    TextField(
                      controller: adetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Adet *',
                        border: const OutlineInputBorder(),
                        helperText: seciliBeden != null
                            ? 'Mevcut stok: $mevcutStok'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Açıklama
                    TextField(
                      controller: aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (Opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Sarf Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  // Validasyon
                  if (seciliBeden == null) {
                    ctx.showErrorSnackBar('Beden seçiniz');
                    return;
                  }
                  if (seciliFirma == null) {
                    ctx.showErrorSnackBar('Firma seçiniz');
                    return;
                  }
                  final adet = int.tryParse(adetController.text.trim());
                  if (adet == null || adet <= 0) {
                    ctx.showErrorSnackBar('Geçerli bir adet giriniz');
                    return;
                  }
                  final stok = (seciliBeden!['stok_miktari'] as int?) ?? 0;
                  if (adet > stok) {
                    ctx.showErrorSnackBar(
                        'Stokta yeterli miktar yok (Mevcut: $stok)');
                    return;
                  }

                  try {
                    final firmaId = TenantManager.instance.requireFirmaId;

                    // 1. Stoktan düş
                    await supabase
                        .from(DbTables.aksesuarBedenler)
                        .update({'stok_miktari': stok - adet})
                        .eq('firma_id', firmaId)
                        .eq('id', seciliBeden!['id']);

                    // 2. Sarf hareketi kaydı
                    final tedLabel = (seciliFirma!['sirket'] != null &&
                            seciliFirma!['sirket'].toString().isNotEmpty)
                        ? seciliFirma!['sirket'].toString()
                        : seciliFirma!['ad']?.toString() ?? '';
                    await supabase
                        .from(DbTables.aksesuarStokHareketleri)
                        .insert({
                      'aksesuar_beden_id': seciliBeden!['id'].toString(),
                      'firma_id': firmaId,
                      'hareket_tipi': 'cikis',
                      'miktar': adet,
                      'onceki_stok': stok,
                      'yeni_stok': stok - adet,
                      'aciklama': aciklamaController.text.trim().isEmpty
                          ? null
                          : aciklamaController.text.trim(),
                      'tedarikci_adi': tedLabel.isNotEmpty ? tedLabel : null,
                      if (seciliModel != null)
                        'model_id': seciliModel!['id'].toString(),
                      'kullanici_id': supabase.auth.currentUser?.id,
                    });

                    await _aksesuarToplamStokGuncelle(
                        aksesuar['id'].toString());

                    final yeniStok = stok - adet;
                    final minimumStok =
                        (aksesuar['minimum_stok'] as num?)?.toDouble() ?? 10;
                    if (yeniStok <= minimumStok) {
                      await BildirimService().stokKritikUyarisi(
                        stokAdi: '${aksesuar['ad']} - ${seciliBeden!['beden']}',
                        mevcutMiktar: yeniStok.toDouble(),
                        kritikSeviye: minimumStok,
                        birim: 'adet',
                      );
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    context.showSuccessSnackBar(
                      '${aksesuar['ad']} - ${seciliBeden!['beden']}: $adet adet sarf edildi',
                    );

                    // Listeyi yenile
                    await _loadAksesuarlar();
                    _loadSarfKayitlari();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ctx.showErrorSnackBar('Sarf hatası: $e');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
