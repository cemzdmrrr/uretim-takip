// ignore_for_file: invalid_use_of_protected_member
part of 'utu_paket_dashboard.dart';

/// Çeki CRUD işlemleri (düzenle, gönderim, sil, ekle) for _UtuPaketDashboardState.
extension _CekiIslemleriExt on _UtuPaketDashboardState {
  // ===== ÇEKİ LISTESI DÜZENLE =====
  Future<void> _cekiDuzenleDialogu(Map<String, dynamic> kayit) async {
    final koliNoController =
        TextEditingController(text: kayit['koli_no'] ?? '');
    final koliAdediController =
        TextEditingController(text: (kayit['koli_adedi'] ?? 1).toString());
    final adetController =
        TextEditingController(text: (kayit['adet'] ?? 0).toString());
    final bedenController =
        TextEditingController(text: kayit['beden_kodu'] ?? '');
    final adetPerKoliController =
        TextEditingController(text: (kayit['adet_per_koli'] ?? '').toString());
    final notController = TextEditingController(text: kayit['notlar'] ?? '');

    // Mix koli kontrolü
    final isMixKoli = kayit['beden_kodu'] == 'MIX';
    final mixBedenDetay = kayit['mix_beden_detay'] as List<dynamic>?;
    final Map<String, int> bedenAdetleri = {};
    
    if (isMixKoli && mixBedenDetay != null) {
      for (var item in mixBedenDetay) {
        bedenAdetleri[item['beden']] = item['adet'];
      }
    }

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Toplam adet hesapla
          int toplamKoliBasiAdet = 0;
          if (isMixKoli) {
            toplamKoliBasiAdet = bedenAdetleri.values.fold(0, (a, b) => a + b);
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text('Çeki Listesi Düzenle'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: koliNoController,
                      decoration: const InputDecoration(
                        labelText: 'Koli No',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Mix koli ise beden düzenlemesi
                    if (isMixKoli && bedenAdetleri.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shuffle, color: Colors.purple[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Mix Koli - Beden Düzenle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            ...bedenAdetleri.keys.map((beden) {
                              final controller = TextEditingController(
                                text: bedenAdetleri[beden].toString(),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.purple[300]!),
                                      ),
                                      child: Text(
                                        beden,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          labelText: 'Adet',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          final adet = int.tryParse(value) ?? 0;
                                          setDialogState(() {
                                            bedenAdetleri[beden] = adet;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Koli Başı Toplam:',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('$toplamKoliBasiAdet adet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[700],
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: koliAdediController,
                        decoration: const InputDecoration(
                          labelText: 'Koli Adedi',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Toplam Adet:',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${toplamKoliBasiAdet * (int.tryParse(koliAdediController.text) ?? 1)} adet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Normal koli düzenleme
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: koliAdediController,
                              decoration: const InputDecoration(
                                labelText: 'Koli Adedi',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: adetController,
                              decoration: const InputDecoration(
                                labelText: 'Toplam Adet',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bedenController,
                              decoration: const InputDecoration(
                                labelText: 'Beden',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: adetPerKoliController,
                              decoration: const InputDecoration(
                                labelText: 'Adet/Koli',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notController,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          );
        },
      ),
    );

    if (sonuc == true) {
      try {
        Map<String, dynamic> updateData;
        
        if (isMixKoli && bedenAdetleri.isNotEmpty) {
          // Mix koli güncelleme
          final koliSayisi = int.tryParse(koliAdediController.text) ?? 1;
          final koliBasiAdet = bedenAdetleri.values.fold(0, (a, b) => a + b);
          
          updateData = {
            'koli_no': koliNoController.text,
            'koli_adedi': koliSayisi,
            'adet': koliBasiAdet * koliSayisi,
            'beden_kodu': 'MIX',
            'adet_per_koli': koliBasiAdet,
            'mix_beden_detay': bedenAdetleri.entries
                .map((e) => {'beden': e.key, 'adet': e.value})
                .toList(),
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          };
        } else {
          // Normal koli güncelleme
          updateData = {
            'koli_no': koliNoController.text,
            'koli_adedi': int.tryParse(koliAdediController.text) ?? 1,
            'adet': int.tryParse(adetController.text) ?? 0,
            'beden_kodu':
                bedenController.text.isNotEmpty ? bedenController.text : null,
            'adet_per_koli': adetPerKoliController.text.isNotEmpty
                ? int.tryParse(adetPerKoliController.text)
                : null,
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          };
        }

        await supabase
            .from(DbTables.cekiListesi)
            .update(updateData)
            .eq('id', kayit['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Çeki listesi kaydı güncellendi'),
                backgroundColor: Colors.blue),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Güncelleme hatası: $e');
      }
    }
  }

  Future<void> _gonderimDurumuGuncelle(Map<String, dynamic> kayit) async {
    final kargoController =
        TextEditingController(text: kayit['kargo_firmasi'] ?? '');
    final takipNoController =
        TextEditingController(text: kayit['takip_no'] ?? '');
    final aliciController =
        TextEditingController(text: kayit['alici_bilgisi'] ?? '');

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Gönderim Bilgileri'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: kargoController,
                  decoration: const InputDecoration(
                    labelText: 'Kargo Firması',
                    hintText: 'Örn: Yurtiçi Kargo, Aras Kargo',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: takipNoController,
                  decoration: const InputDecoration(
                    labelText: 'Takip Numarası',
                    hintText: 'Kargo takip numarası',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aliciController,
                  decoration: const InputDecoration(
                    labelText: 'Alıcı Bilgisi',
                    hintText: 'İsim veya firma adı',
                    prefixIcon: Icon(Icons.person),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Gönderildi Olarak İşaretle'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );

    if (sonuc == true) {
      try {
        final modelId = kayit['model_id'];
        final gonderilecekAdet = kayit['adet'] ?? 0;
        
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🚀 ÇEKİ GÖNDERİM İŞLEMİ BAŞLADI');
        debugPrint('Model ID: $modelId');
        debugPrint('Gönderilecek Adet: $gonderilecekAdet');
        debugPrint('Çeki ID: ${kayit['id']}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // ===== 1. ÇEKİ LİSTESİNİ GÜNCELLE =====
        debugPrint('📝 1. Çeki listesi güncelleniyor...');
        await supabase.from(DbTables.cekiListesi).update({
          'gonderim_durumu': 'gonderildi',
          'gonderim_tarihi': DateTime.now().toIso8601String(),
          'kargo_firmasi':
              kargoController.text.isNotEmpty ? kargoController.text : null,
          'takip_no':
              takipNoController.text.isNotEmpty ? takipNoController.text : null,
          'alici_bilgisi':
              aliciController.text.isNotEmpty ? aliciController.text : null,
        }).eq('id', kayit['id']);
        debugPrint('✅ Çeki listesi güncellendi');

        // ===== 2. MODEL DETAY'DA YÜKLEME KAYDI EKLE =====
        // Çeki gönderimi = Ürün yükleme (sevkiyat)
        debugPrint('📦 2. Yükleme kaydı ekleniyor...');
        try {
          if (modelId == null) {
            throw Exception('Model ID null! Kayıt: $kayit');
          }
          
          final yuklemeData = {
            'model_id': modelId,
            'adet': gonderilecekAdet,
            'tarih': DateTime.now().toIso8601String(),
            'kaynak': DbTables.cekiListesi,
            'ceki_id': kayit['id'],
          };
          
          debugPrint('📋 Eklenecek veri: $yuklemeData');
          
          final result = await supabase.from(DbTables.yuklemeKayitlari).insert(yuklemeData).select();
          
          debugPrint('✅✅✅ YÜKLEME KAYDI BAŞARIYLA EKLENDİ!');
          debugPrint('Sonuç: $result');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          // Gelişmiş raporlar için hesaplamaları tetikle
          try {
            await _guncelleGelismisRaporlar(modelId);
            debugPrint('📊 Gelişmiş raporlar güncellendi');
          } catch (raporHatasi) {
            debugPrint('⚠️ Rapor güncelleme hatası: $raporHatasi');
          }
        } catch (yuklemeHatasi) {
          debugPrint('❌❌❌ YÜKLEME KAYDI HATASI!');
          debugPrint('Hata: $yuklemeHatasi');
          debugPrint('Hata Tipi: ${yuklemeHatasi.runtimeType}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Yükleme kaydı eklenemedi: $yuklemeHatasi'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        if (mounted) {
          context.showSuccessSnackBar('✅ Çeki gönderildi (Ürün yükleme sekmesine eklendi)');
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Güncelleme hatası: $e');
      }
    }
  }

  // ===== ÇEKİ SİL =====
  Future<void> _cekiSil(Map<String, dynamic> kayit) async {
    final model = kayit[DbTables.trikoTakip] as Map<String, dynamic>?;
    final koliNo = kayit['koli_no'] ?? 'Koli';

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Çeki Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu çeki kaydını silmek istediğinize emin misiniz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Koli: $koliNo',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (model != null)
                    Text('${model['marka']} - ${model['item_no']}'),
                  Text('Adet: ${kayit['adet'] ?? 0}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Sil'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (sonuc == true) {
      try {
        // Rate limiting için küçük bir delay ekle
        await Future.delayed(const Duration(milliseconds: 300));

        await supabase.from(DbTables.cekiListesi).delete().eq('id', kayit['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Çeki kaydı silindi'),
                backgroundColor: Colors.orange),
          );
          _verileriYukle();
        }
      } catch (e) {
        if (e.toString().contains('ThrottlerException') ||
            e.toString().contains('Too Many Requests')) {
          _hataGoster(
              'Çok hızlı silme işlemi yapıldı. Lütfen birkaç saniye bekleyip tekrar deneyin.');
        } else {
          _hataGoster('Silme hatası: $e');
        }
      }
    }
  }

  // Toplu çeki silme (Rate limiting'den kaçınmak için optimize edilmiş)
  Future<void> _modelCekileriniTopluSil(
      List<Map<String, dynamic>> koliler) async {
    if (koliler.isEmpty) return;

    final model = (koliler.first[DbTables.trikoTakip] as Map<String, dynamic>?);
    final modelAdi = '${model?['marka'] ?? '-'} - ${model?['item_no'] ?? '-'}';

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
        title: const Text('Toplu Silme Onayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$modelAdi modeline ait'),
            Text('${koliler.length} adet çeki kaydı silinecek.',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Bu işlem geri alınamaz!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Tümünü Sil'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (sonuc == true) {
      try {
        // Tüm ID'leri topla
        final ids = koliler.map((k) => k['id']).whereType<int>().toList();

        if (ids.isEmpty) {
          _hataGoster('Silinecek kayıt bulunamadı');
          return;
        }

        // Tek bir sorgu ile tümünü sil (Rate limiting'den kaçınmak için)
        await supabase.from(DbTables.cekiListesi).delete().inFilter('id', ids);

        if (mounted) {
          context.showSuccessSnackBar('✅ ${ids.length} adet çeki kaydı silindi');
          _verileriYukle();
        }
      } catch (e) {
        if (e.toString().contains('ThrottlerException') ||
            e.toString().contains('Too Many Requests')) {
          _hataGoster(
              'Çok fazla istek gönderildi. Lütfen birkaç saniye bekleyip tekrar deneyin.');
        } else {
          _hataGoster('Toplu silme hatası: $e');
        }
      }
    }
  }

  Future<void> _yeniCekiEkle() async {
    // Tamamlanan paketlemelerden model seçtir
    final tamamlananModeller = <Map<String, dynamic>>[];

    // Tüm modellerden benzersiz olanları al
    for (var atama in [
      ...paketBekleyenler,
      ...paketOnaylananlar,
      ...paketUretimde,
      ...paketTamamlananlar
    ]) {
      final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
      if (model != null) {
        if (!tamamlananModeller.any((m) => m['id'] == model['id'])) {
          tamamlananModeller.add({...model, 'atama': atama});
        }
      }
    }

    if (tamamlananModeller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Eklenecek model bulunamadı'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    Map<String, dynamic>? seciliModel;
    final koliAdetiController = TextEditingController(text: '1');
    final adetPerKoliController = TextEditingController(text: '10');
    final notController = TextEditingController();
    
    // Mix koli için beden listesi: {beden: adet}
    final Map<String, int> bedenAdetleri = {};
    bool isMixKoli = false;

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Seçili modelin bedenleri
          List<String> bedenler = ['Genel'];
          if (seciliModel != null) {
            final bedenlerRaw = seciliModel!['bedenler'];
            if (bedenlerRaw is Map) {
              bedenler = bedenlerRaw.keys.map((e) => e.toString()).toList();
            }
            if (bedenler.isEmpty) bedenler = ['Genel'];
          }

          // Toplam adet hesapla
          int toplamAdet = 0;
          if (isMixKoli) {
            toplamAdet = bedenAdetleri.values.fold(0, (a, b) => a + b);
          } else {
            final koli = int.tryParse(koliAdetiController.text) ?? 1;
            final perKoli = int.tryParse(adetPerKoliController.text) ?? 10;
            toplamAdet = koli * perKoli;
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_box, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text('Yeni Çeki Ekle'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model seçimi
                    DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: seciliModel,
                      decoration: const InputDecoration(
                        labelText: 'Model Seç',
                        prefixIcon: Icon(Icons.checkroom),
                        border: OutlineInputBorder(),
                      ),
                      items: tamamlananModeller
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('${m['marka']} - ${m['item_no']}',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          seciliModel = value;
                          bedenAdetleri.clear();
                          isMixKoli = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mix koli toggle
                    if (seciliModel != null && bedenler.length > 1) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMixKoli ? Colors.purple[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMixKoli ? Colors.purple : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shuffle,
                              color: isMixKoli ? Colors.purple[700] : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mix Koli',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isMixKoli ? Colors.purple[700] : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'Bir koliye birden fazla beden',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isMixKoli,
                              activeThumbColor: Colors.purple[700],
                              onChanged: (value) {
                                setDialogState(() {
                                  isMixKoli = value;
                                  if (!value) {
                                    bedenAdetleri.clear();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Mix koli ise beden seçimi ve adet girişi
                    if (isMixKoli && seciliModel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Koli İçeriği',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple[700],
                                  ),
                                ),
                                if (bedenAdetleri.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[700],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Toplam: $toplamAdet adet',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Bedenleri göster
                            ...bedenler.where((b) => b != 'Genel').map((beden) {
                              final controller = TextEditingController(
                                text: bedenAdetleri[beden]?.toString() ?? '',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.purple[300]!),
                                      ),
                                      child: Text(
                                        beden,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: 'Adet',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          final adet = int.tryParse(value) ?? 0;
                                          setDialogState(() {
                                            if (adet > 0) {
                                              bedenAdetleri[beden] = adet;
                                            } else {
                                              bedenAdetleri.remove(beden);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: koliAdetiController,
                        decoration: const InputDecoration(
                          labelText: 'Koli Sayısı',
                          prefixIcon: Icon(Icons.inventory_2),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ] else if (!isMixKoli && seciliModel != null) ...[
                      // Normal mod - tek beden
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: koliAdetiController,
                              decoration: const InputDecoration(
                                labelText: 'Koli Sayısı',
                                prefixIcon: Icon(Icons.inventory_2),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: adetPerKoliController,
                              decoration: const InputDecoration(
                                labelText: 'Koli Başı Adet',
                                prefixIcon: Icon(Icons.all_inbox),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 12),

                    // Toplam adet göster
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam Adet:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            '$toplamAdet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notController,
                      decoration: const InputDecoration(
                        labelText: 'Not (Opsiyonel)',
                        prefixIcon: Icon(Icons.note),
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: seciliModel == null || 
                           (isMixKoli && bedenAdetleri.isEmpty) ||
                           (!isMixKoli && toplamAdet == 0)
                    ? null
                    : () => Navigator.pop(context, true),
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700]),
              ),
            ],
          );
        },
      ),
    );

    if (sonuc == true && seciliModel != null) {
      try {
        if (isMixKoli && bedenAdetleri.isNotEmpty) {
          // Mix koli - JSON olarak kaydet
          final koliSayisi = int.tryParse(koliAdetiController.text) ?? 1;
          final toplamAdet = bedenAdetleri.values.fold(0, (a, b) => a + b);
          
          await supabase.from(DbTables.cekiListesi).insert({
            'model_id': seciliModel!['id'],
            'beden_kodu': 'MIX',
            'koli_adedi': koliSayisi,
            'adet': toplamAdet * koliSayisi,
            'adet_per_koli': toplamAdet,
            'mix_beden_detay': bedenAdetleri.entries
                .map((e) => {'beden': e.key, 'adet': e.value})
                .toList(),
            'paketleme_tarihi': DateTime.now().toIso8601String(),
            'gonderim_durumu': 'bekliyor',
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          });
        } else {
          // Normal koli - tek beden
          final koliSayisi = int.tryParse(koliAdetiController.text) ?? 1;
          final adetPerKoli = int.tryParse(adetPerKoliController.text) ?? 10;
          
          await supabase.from(DbTables.cekiListesi).insert({
            'model_id': seciliModel!['id'],
            'beden_kodu': null,
            'koli_adedi': koliSayisi,
            'adet': koliSayisi * adetPerKoli,
            'adet_per_koli': adetPerKoli,
            'paketleme_tarihi': DateTime.now().toIso8601String(),
            'gonderim_durumu': 'bekliyor',
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Çeki listesine eklendi'),
                backgroundColor: Colors.green),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Ekleme hatası: $e');
      }
    }
  }
}
