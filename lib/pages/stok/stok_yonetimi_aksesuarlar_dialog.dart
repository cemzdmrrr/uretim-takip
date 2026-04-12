// ignore_for_file: invalid_use_of_protected_member
part of 'stok_yonetimi_aksesuarlar_coklu_beden.dart';

/// Stok yonetimi aksesuarlar - dialog metotlari
extension _DialogExt on _StokYonetimiAksesuarlarCokluBedenState {
  void _showAddEditDialog({Map<String, dynamic>? aksesuar}) {
    final isEdit = aksesuar != null;
    
    // Form controllers
    final skuController = TextEditingController(text: aksesuar?['sku'] ?? '');
    final adController = TextEditingController(text: aksesuar?['ad'] ?? '');
    final markaController = TextEditingController(text: aksesuar?['marka'] ?? '');
    final renkController = TextEditingController(text: aksesuar?['renk'] ?? '');
    final renkKoduController = TextEditingController(text: aksesuar?['renk_kodu'] ?? '');
    final birimController = TextEditingController(text: aksesuar?['birim'] ?? 'adet');
    final birimFiyatController = TextEditingController(text: aksesuar?['birim_fiyat']?.toString() ?? '');
    final malzemeController = TextEditingController(text: aksesuar?['malzeme'] ?? '');
    final aciklamaController = TextEditingController(text: aksesuar?['aciklama'] ?? '');
    final minimumStokController = TextEditingController(text: aksesuar?['minimum_stok']?.toString() ?? '10');
    
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      helperText: 'Toplam stok bu değerin altına düştüğünde uyarı verilir',
                    ),
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
                              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              border: index > 0 ? Border(top: BorderSide(color: Colors.grey.shade300)) : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Beden: ${beden['beden']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showBedenDuzenleDialog(index, beden, setStateModal, bedenListesi),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
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
                      onPressed: () => _showBedenEklemeDialog(setStateModal, bedenListesi),
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
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
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
              bedenListesi,
            ),
            child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showBedenEklemeDialog(StateSetter setStateModal, List<Map<String, dynamic>> bedenListesi) {
    final TextEditingController bedenController = TextEditingController();
    final TextEditingController stokController = TextEditingController(text: '0');
    
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
                  b['beden'].toString().toLowerCase() == bedenController.text.trim().toLowerCase()
                );
                
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

  void _showBedenDuzenleDialog(int index, Map<String, dynamic> beden, StateSetter setStateModal, List<Map<String, dynamic>> bedenListesi) {
    final TextEditingController bedenController = TextEditingController(text: beden['beden']);
    final TextEditingController stokController = TextEditingController(text: beden['stok_miktari'].toString());
    
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
      // 1. Ana aksesuar kaydını oluştur/güncelle
      final aksesuarData = {
        'sku': skuController.text.trim(),
        'ad': adController.text.trim(),
        'marka': markaController.text.trim().isNotEmpty ? markaController.text.trim() : null,
        'renk': renkController.text.trim().isNotEmpty ? renkController.text.trim() : null,
        'renk_kodu': renkKoduController.text.trim().isNotEmpty ? renkKoduController.text.trim() : null,
        'birim': birimController.text.trim().isNotEmpty ? birimController.text.trim() : 'adet',
        'birim_fiyat': double.tryParse(birimFiyatController.text.replaceAll(',', '.')) ?? 0.0,
        'malzeme': malzemeController.text.trim().isNotEmpty ? malzemeController.text.trim() : null,
        'aciklama': aciklamaController.text.trim().isNotEmpty ? aciklamaController.text.trim() : null,
        'minimum_stok': int.tryParse(minimumStokController.text) ?? 10,
        'durum': 'aktif',
        'updated_at': DateTime.now().toIso8601String(),
        if (!isEdit) 'firma_id': TenantManager.instance.requireFirmaId,
      };
      
      debugPrint('📝 Aksesuar kayıt verisi: $aksesuarData');
      debugPrint('💰 Birim Fiyat Controller değeri: "${birimFiyatController.text}"');
      debugPrint('💰 Birim Fiyat parse edilmiş: ${aksesuarData['birim_fiyat']}');

      String finalAksesuarId;
      
      if (isEdit && aksesuarId != null) {
        // Güncelleme
        debugPrint('🔄 Aksesuar güncelleniyor: $aksesuarId');
        final updateResult = await supabase
            .from(DbTables.aksesuarlar)
            .update(aksesuarData)
            .eq('id', aksesuarId)
            .select()
            .single();
        finalAksesuarId = aksesuarId;
        debugPrint('✅ Aksesuar güncellendi: $updateResult');
        
        // Mevcut bedenlerini pasif yap
        await supabase.from(DbTables.aksesuarBedenler)
            .update({'durum': 'pasif'})
            .eq('aksesuar_id', aksesuarId);
        debugPrint('✅ Eski bedenler pasif yapıldı');
        
      } else {
        // Yeni kayıt
        debugPrint('➕ Yeni aksesuar ekleniyor...');
        final result = await supabase.from(DbTables.aksesuarlar).insert(aksesuarData).select('id').single();
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
            .eq('aksesuar_id', finalAksesuarId)
            .eq('beden', bedenAdi)
            .maybeSingle();
        
        if (mevcutBeden != null) {
          // Mevcut bedeni güncelle
          await supabase.from(DbTables.aksesuarBedenler).update({
            'stok_miktari': stokMiktari,
            'durum': 'aktif',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', mevcutBeden['id']);
          debugPrint('  ✅ Beden güncellendi: $bedenAdi (stok: $stokMiktari)');
        } else {
          // Yeni beden ekle
          await supabase.from(DbTables.aksesuarBedenler).insert({
            'aksesuar_id': finalAksesuarId,
            'beden': bedenAdi,
            'stok_miktari': stokMiktari,
            'durum': 'aktif',
            'firma_id': TenantManager.instance.requireFirmaId,
          });
          debugPrint('  ✅ Yeni beden eklendi: $bedenAdi (stok: $stokMiktari)');
        }
      }
      
      // 3. Ana aksesuar tablosundaki toplam miktar alanını güncelle
      await supabase.from(DbTables.aksesuarlar).update({
        'miktar': toplamStok,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', finalAksesuarId);
      debugPrint('📊 Toplam stok güncellendi: $toplamStok');

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Aksesuar başarıyla güncellendi' : 'Aksesuar başarıyla eklendi'),
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
  void _showSarfDialog(Map<String, dynamic> aksesuar) {
    final bedenler = (aksesuar['aksesuar_bedenler'] as List?)
        ?.where((b) => b['durum'] == 'aktif' && (b['stok_miktari'] as int? ?? 0) > 0)
        .toList() ?? [];

    if (bedenler.isEmpty) {
      context.showErrorSnackBar('Bu aksesuarın stokta bedeni yok');
      return;
    }

    final adetController = TextEditingController();
    final aciklamaController = TextEditingController();
    Map<String, dynamic>? seciliBeden = bedenler.length == 1 ? bedenler.first : null;
    Map<String, dynamic>? seciliFirma;
    List<Map<String, dynamic>> firmalar = [];
    bool firmaYukleniyor = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          // Firmaları yükle (ilk açılışta)
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
                      items: bedenler.map((b) => DropdownMenuItem<Map<String, dynamic>>(
                        value: b,
                        child: Text('${b['beden']}  (Stok: ${b['stok_miktari']})'),
                      )).toList(),
                      onChanged: (val) => setStateDialog(() => seciliBeden = val),
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
                        final label = f['sirket'] != null && f['sirket'].toString().isNotEmpty
                            ? f['sirket']
                            : '${f['ad'] ?? ''}'.trim();
                        return DropdownMenuItem<Map<String, dynamic>>(value: f, child: Text(label));
                      }).toList(),
                      onChanged: (val) => setStateDialog(() => seciliFirma = val),
                    ),
                    const SizedBox(height: 12),

                    // Adet
                    TextField(
                      controller: adetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Adet *',
                        border: const OutlineInputBorder(),
                        helperText: seciliBeden != null ? 'Mevcut stok: $mevcutStok' : null,
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
                    ctx.showErrorSnackBar('Stokta yeterli miktar yok (Mevcut: $stok)');
                    return;
                  }

                  try {
                    final firmaId = TenantManager.instance.requireFirmaId;

                    // 1. Stoktan düş
                    await supabase
                        .from(DbTables.aksesuarBedenler)
                        .update({'stok_miktari': stok - adet})
                        .eq('id', seciliBeden!['id']);

                    // 2. Kullanım kaydı oluştur
                    await supabase
                        .from(DbTables.aksesuarKullanim)
                        .insert({
                      'aksesuar_id': aksesuar['id'].toString(),
                      'beden_id': seciliBeden!['id'].toString(),
                      'beden': seciliBeden!['beden'],
                      'musteri_id': seciliFirma!['id'].toString(),
                      'miktar': adet,
                      'islem_tipi': 'sarf',
                      'aciklama': aciklamaController.text.trim().isEmpty
                          ? null
                          : aciklamaController.text.trim(),
                      'firma_id': firmaId,
                    });

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    context.showSuccessSnackBar(
                      '${aksesuar['ad']} - ${seciliBeden!['beden']}: $adet adet sarf edildi',
                    );

                    // Listeyi yenile
                    await _loadAksesuarlar();
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
