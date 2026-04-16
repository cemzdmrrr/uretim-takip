// ignore_for_file: invalid_use_of_protected_member
part of 'utu_paket_dashboard.dart';

/// Paketleme işlemleri (başla, tamamla, mix koli) for _UtuPaketDashboardState.
extension _PaketlemeExt on _UtuPaketDashboardState {
  // ===== PAKETLEMEYE BAŞLA DİALOGU =====
  Future<void> _paketlemeyeBaslaDialogu(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.brown),
            SizedBox(width: 8),
            Text('Paketlemeye Başla'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${model?['marka']} - ${model?['item_no']}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Renk: ${model?['renk'] ?? '-'}'),
            Text(
                'Talep: ${atama['talep_edilen_adet'] ?? atama['adet'] ?? 0} adet'),
            const SizedBox(height: 16),
            const Text('Paketleme işlemini başlatmak istiyor musunuz?',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İşlemde durumuna geçtikten sonra beden bazlı paketleme girişi yapabilirsiniz.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
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
            icon: const Icon(Icons.play_arrow),
            label: const Text('Başlat'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );

    if (sonuc == true) {
      try {
        await supabase.from(DbTables.paketlemeAtamalari).update({
          'durum': 'devam_ediyor',
        }).eq('id', atama['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Paketleme başlatıldı'),
                backgroundColor: Colors.blue),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Başlatma hatası: $e');
      }
    }
  }

  Future<void> _tamamlaDialoguGoster(
      Map<String, dynamic> atama, String tip) async {
    // Paketleme için beden bazlı tamamlama dialogu göster
    if (tip == 'paketleme') {
      await _paketlemeBedenliBitirDialogu(atama);
      return;
    }

    // Ütü için kısmi tamamlama dialog'u
    final talep = atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
    final adetController = TextEditingController(text: talep.toString());
    final notController = TextEditingController();

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Ütü Tamamla'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toplam bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Talep Edilen',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            Text('$talep adet',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                        Icon(Icons.arrow_forward, color: Colors.blue[200]),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Tamamlanacak',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            Text(
                              '${int.tryParse(adetController.text) ?? 0} adet',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tamamlanan adet input
                  TextField(
                    controller: adetController,
                    decoration: InputDecoration(
                      labelText: 'Tamamlanan Adet',
                      hintText: 'Kısmi tamamlama yapabilirsiniz',
                      border: const OutlineInputBorder(),
                      helperText: 'Talep edilen: $talep adet',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Kalan adet gösterimi
                  Builder(
                    builder: (context) {
                      final tamamlanan = int.tryParse(adetController.text) ?? 0;
                      final kalan = talep - tamamlanan;
                      final uyari = kalan < 0
                          ? ' ⚠️ Talep edilen miktarı aşıyor!'
                          : kalan > 0
                              ? ' ($kalan adet işlemde devam edecek)'
                              : '';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kalan < 0
                              ? Colors.red[50]
                              : kalan > 0
                                  ? Colors.orange[50]
                                  : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kalan < 0
                                ? Colors.red[200]!
                                : kalan > 0
                                    ? Colors.orange[200]!
                                    : Colors.green[200]!,
                          ),
                        ),
                        child: Text(
                          'Kalan: $kalan adet$uyari',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: kalan < 0
                                ? Colors.red[700]
                                : kalan > 0
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Not
                  TextField(
                    controller: notController,
                    decoration: const InputDecoration(
                      labelText: 'Not (Opsiyonel)',
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
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                final tamamlanan = int.tryParse(adetController.text) ?? 0;
                final talep = atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
                if (tamamlanan > 0 && tamamlanan <= talep) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Tamamla'),
            ),
          ],
        ),
      ),
    );

    if (sonuc == true) {
      try {
        final tamamlananAdet = int.tryParse(adetController.text) ?? 0;
        final talep = atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
        final kalanAdet = talep - tamamlananAdet;

        if (kalanAdet == 0) {
          // Tüm adet tamamlandı - durumu tamamlandı yap
          await supabase.from(DbTables.utuAtamalari).update({
            'durum': 'tamamlandi',
            'tamamlanan_adet': tamamlananAdet,
            'tamamlama_tarihi': DateTime.now().toIso8601String(),
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          }).eq('id', atama['id']);
        } else {
          // Kısmi tamamlama - mevcut atamayı güncelle, kalan için yeni atama oluştur
          await supabase.from(DbTables.utuAtamalari).update({
            'durum': 'kismi_tamamlandi', // Kısmi tamamlandı durumu
            'tamamlanan_adet': tamamlananAdet,
            'talep_edilen_adet': talep, // Orijinal talep tutulsun
            'tamamlama_tarihi': DateTime.now().toIso8601String(),
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          }).eq('id', atama['id']);

          // Kalan adet için yeni atama oluştur
          await supabase.from(DbTables.utuAtamalari).insert({
            'model_id': atama['model_id'],
            'tedarikci_id': atama['tedarikci_id'],
            'talep_edilen_adet': kalanAdet,
            'adet': kalanAdet,
            'durum': 'atandi',
            'atama_tarihi': DateTime.now().toIso8601String(),
            'notlar': 'Kısmi tamamlamadan devam - Kalan adet: $kalanAdet',
            'firma_id': TenantManager.instance.requireFirmaId,
          });

          debugPrint(
              '📦 Kısmi tamamlama: $tamamlananAdet tamamlandı, $kalanAdet adet yeni atama oluşturuldu');
        }

        // ===== ÜTÜ TAMAMLANINCA PAKETLEMEYİ OTOMATİK OLUŞTUR =====
        await _paketlemeyeOtomatikAta(atama, tamamlananAdet);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: kalanAdet > 0
                  ? Text(
                      '✅ $tamamlananAdet adet tamamlandı, $kalanAdet adet işlemde devam ediyor')
                  : const Text('✅ Ütü tamamlandı - Paketlemeye aktarıldı'),
              backgroundColor: Colors.green,
            ),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Tamamlama hatası: $e');
      }
    }
  }

  // ===== ÜTÜ TAMAMLANINCA PAKETLEMEYİ OTOMATİK AT =====
  Future<void> _paketlemeyeOtomatikAta(
      Map<String, dynamic> utuAtama, int tamamlananAdet) async {
    try {
      // Aynı model için paketleme ataması var mı kontrol et
      final mevcutPaketleme = await supabase
          .from(DbTables.paketlemeAtamalari)
          .select('id, adet, durum')
          .eq('model_id', utuAtama['model_id'])
          .neq('durum', 'tamamlandi')
          .maybeSingle();

      if (mevcutPaketleme != null) {
        // Mevcut paketleme atamasının adetini artır
        final yeniAdet = (mevcutPaketleme['adet'] ?? 0) + tamamlananAdet;
        await supabase.from(DbTables.paketlemeAtamalari).update({
          'adet': yeniAdet,
        }).eq('id', mevcutPaketleme['id']);

        debugPrint('Mevcut paketleme atamasına $tamamlananAdet adet eklendi');
      } else {
        // Yeni paketleme ataması oluştur
        await supabase.from(DbTables.paketlemeAtamalari).insert({
          'model_id': utuAtama['model_id'],
          'tedarikci_id': utuAtama['tedarikci_id'],
          'adet': tamamlananAdet,
          'durum': 'bekleyen',
          'onceki_asama': 'utu',
          'atama_tarihi': DateTime.now().toIso8601String(),
          'firma_id': TenantManager.instance.requireFirmaId,
        });

        debugPrint('Yeni paketleme ataması oluşturuldu: $tamamlananAdet adet');
      }
    } catch (e) {
      debugPrint('Paketleme ataması oluşturma hatası: $e');
      // Hata olsa bile ütü tamamlama işlemi başarılı sayılır
    }
  }

  // ===== BEDEN BAZLI PAKETLEME TAMAMLAMA DİALOGU =====
  Future<void> _paketlemeBedenliBitirDialogu(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
    final bedenlerRaw = model?['bedenler'];

    // Bedenleri parse et
    Map<String, int> bedenDagilimi = {};
    if (bedenlerRaw is Map) {
      bedenlerRaw.forEach((key, value) {
        bedenDagilimi[key.toString()] =
            (value is int) ? value : (int.tryParse(value.toString()) ?? 0);
      });
    } else if (bedenlerRaw is String && bedenlerRaw.isNotEmpty) {
      // JSON string ise parse et
      try {
        // Basit parse: "S:100, M:150" gibi formatları da destekle
        if (bedenlerRaw.contains(':')) {
          bedenlerRaw.split(',').forEach((item) {
            final parts = item.trim().split(':');
            if (parts.length == 2) {
              bedenDagilimi[parts[0].trim()] =
                  int.tryParse(parts[1].trim()) ?? 0;
            }
          });
        }
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
    }

    // Eğer beden bilgisi yoksa varsayılan ekle
    if (bedenDagilimi.isEmpty) {
      bedenDagilimi = {
        'Genel': atama['talep_edilen_adet'] ?? atama['adet'] ?? 0
      };
    }

    // Her beden için controller'lar
    final Map<String, TextEditingController> adetControllers = {};
    final Map<String, TextEditingController> koliControllers = {};
    final Map<String, TextEditingController> adetPerKoliControllers = {};

    for (var beden in bedenDagilimi.keys) {
      adetControllers[beden] =
          TextEditingController(text: bedenDagilimi[beden].toString());
      koliControllers[beden] = TextEditingController(text: '1');
      adetPerKoliControllers[beden] = TextEditingController(text: '10');
    }

    final notController = TextEditingController();

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.brown),
              SizedBox(width: 8),
              Text('Paketleme Tamamla'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.checkroom, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${model?['marka']} - ${model?['item_no']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('Renk: ${model?['renk'] ?? '-'}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Beden bazlı giriş tablosu
                  const Text('Beden Bazlı Paketleme',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),

                  // Tablo başlıkları
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text('Beden',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Adet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Koli/Adet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Koli Sayısı',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                      ],
                    ),
                  ),

                  // Beden satırları
                  ...bedenDagilimi.keys.map((beden) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          // Beden
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(beden,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Adet
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: adetControllers[beden],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Koli başı adet
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: adetPerKoliControllers[beden],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Koli sayısı (hesaplanmış)
                          Expanded(
                            flex: 2,
                            child: Builder(
                              builder: (context) {
                                final adet = int.tryParse(
                                        adetControllers[beden]!.text) ??
                                    0;
                                final perKoli = int.tryParse(
                                        adetPerKoliControllers[beden]!.text) ??
                                    1;
                                final koliSayisi =
                                    perKoli > 0 ? (adet / perKoli).ceil() : 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Text('$koliSayisi koli',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                          fontSize: 12)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Toplam özet
                  Builder(
                    builder: (context) {
                      int toplamAdet = 0;
                      int toplamKoli = 0;
                      for (var beden in bedenDagilimi.keys) {
                        final adet =
                            int.tryParse(adetControllers[beden]!.text) ?? 0;
                        final perKoli =
                            int.tryParse(adetPerKoliControllers[beden]!.text) ??
                                1;
                        toplamAdet += adet;
                        toplamKoli += perKoli > 0 ? (adet / perKoli).ceil() : 0;
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Toplam Adet',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                                Text('$toplamAdet',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700])),
                              ],
                            ),
                            Container(
                                width: 1, height: 40, color: Colors.green[200]),
                            Column(
                              children: [
                                Text('Toplam Koli',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                                Text('$toplamKoli',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700])),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: notController,
                    decoration: const InputDecoration(
                      labelText: 'Not (Opsiyonel)',
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
              label: const Text('Tamamla'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );

    if (sonuc == true) {
      try {
        // Toplam adet ve koli hesapla
        int toplamAdet = 0;
        int toplamKoli = 0;
        final List<Map<String, dynamic>> bedenDetaylari = [];

        for (var beden in bedenDagilimi.keys) {
          final adet = int.tryParse(adetControllers[beden]!.text) ?? 0;
          final perKoli =
              int.tryParse(adetPerKoliControllers[beden]!.text) ?? 1;
          final koliSayisi = perKoli > 0 ? (adet / perKoli).ceil() : 0;

          toplamAdet += adet;
          toplamKoli += koliSayisi;

          bedenDetaylari.add({
            'beden_kodu': beden,
            'adet': adet,
            'adet_per_koli': perKoli,
            'koli_sayisi': koliSayisi,
          });
        }

        // Talep edilen adet ile kısmi tamamlama kontrolü
        final int talepEdilenAdet = atama['talep_edilen_adet'] ?? 0;
        final int kalanAdet = talepEdilenAdet - toplamAdet;

        // Kısmi tamamlama mı yoksa tam tamamlama mı?
        if (kalanAdet == 0) {
          // Tam tamamlandı
          await supabase.from(DbTables.paketlemeAtamalari).update({
            'durum': 'tamamlandi',
            'tamamlanan_adet': toplamAdet,
            'tamamlama_tarihi': DateTime.now().toIso8601String(),
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          }).eq('id', atama['id']);
        } else if (kalanAdet > 0) {
          // Kısmi tamamlandı - işlemde kalmalı
          await supabase.from(DbTables.paketlemeAtamalari).update({
            'durum': 'kismi_tamamlandi',
            'tamamlanan_adet': toplamAdet,
            'tamamlama_tarihi': DateTime.now().toIso8601String(),
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          }).eq('id', atama['id']);

          // Kalan adet için yeni atama oluştur
          await supabase.from(DbTables.paketlemeAtamalari).insert({
            'model_id': atama['model_id'],
            'talep_edilen_adet': kalanAdet,
            'durum': 'bekliyor',
            'baslangic_tarihi': DateTime.now().toIso8601String(),
            'notlar': 'Kalan adet (Önceki atama: ${atama['id']})',
            'firma_id': TenantManager.instance.requireFirmaId,
          });
        } else {
          // Fazla tamamlandı
          await supabase.from(DbTables.paketlemeAtamalari).update({
            'durum': 'tamamlandi',
            'tamamlanan_adet': toplamAdet,
            'tamamlama_tarihi': DateTime.now().toIso8601String(),
            'notlar': notController.text.isNotEmpty ? notController.text : null,
          }).eq('id', atama['id']);
        }

        // Çeki listesine ekle (beden bazlı)
        for (var beden in bedenDetaylari) {
          if (beden['adet'] > 0) {
            try {
              await supabase.from(DbTables.cekiListesi).insert({
                'model_id': atama['model_id'],
                'beden_kodu': beden['beden_kodu'],
                'koli_adedi': beden['koli_sayisi'],
                'adet': beden['adet'],
                'adet_per_koli': beden['adet_per_koli'],
                'paketleme_tarihi': DateTime.now().toIso8601String(),
                'gonderim_durumu': 'bekliyor',
                'notlar':
                    notController.text.isNotEmpty ? notController.text : null,
              });
            } catch (e) {
              debugPrint('Çeki listesi kaydetme hatası: $e');
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Paketleme tamamlandı - $toplamAdet adet, $toplamKoli koli'),
              backgroundColor: Colors.green,
            ),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Tamamlama hatası: $e');
      }
    }

    // Controller'ları temizle
    for (var c in adetControllers.values) {
      c.dispose();
    }
    for (var c in koliControllers.values) {
      c.dispose();
    }
    for (var c in adetPerKoliControllers.values) {
      c.dispose();
    }
    notController.dispose();
  }

  // ===== MIX KOLİ (KARIŞIK BEDEN) DİALOGU =====
  Future<void> _mixKoliDialogu(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
    final bedenlerRaw = model?['bedenler'];

    // Bedenleri parse et
    List<String> bedenListesi = [];
    if (bedenlerRaw is Map) {
      bedenListesi = bedenlerRaw.keys.map((k) => k.toString()).toList();
    }
    if (bedenListesi.isEmpty) {
      bedenListesi = ['S', 'M', 'L', 'XL'];
    }

    // Mix koli için controller'lar
    final koliSayisiController = TextEditingController(text: '1');
    final Map<String, TextEditingController> bedenAdetControllers = {};
    for (var beden in bedenListesi) {
      bedenAdetControllers[beden] = TextEditingController(text: '0');
    }
    final notController = TextEditingController();

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shuffle, color: Colors.purple),
              SizedBox(width: 8),
              Text('Mix Koli Oluştur'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.checkroom, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${model?['marka']} - ${model?['item_no']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('Renk: ${model?['renk'] ?? '-'}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Açıklama
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mix koli: Bir kolide birden fazla beden bulunur.\nÖrn: 1 kolide 3xS + 4xM + 3xL = 10 adet',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Koli sayısı
                  Row(
                    children: [
                      const Text('Kaç koli yapılacak?',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: koliSayisiController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Her kolide kaç adet beden var
                  const Text('Her kolide beden dağılımı:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),

                  ...bedenListesi.map((beden) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(beden,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: bedenAdetControllers[beden],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(),
                                hintText: 'Adet',
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('adet/koli'),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Özet hesaplama
                  Builder(
                    builder: (context) {
                      final koliSayisi =
                          int.tryParse(koliSayisiController.text) ?? 1;
                      int adetPerKoli = 0;
                      for (var beden in bedenListesi) {
                        adetPerKoli +=
                            int.tryParse(bedenAdetControllers[beden]!.text) ??
                                0;
                      }
                      final toplamAdet = koliSayisi * adetPerKoli;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.purple[100]!,
                            Colors.purple[50]!
                          ]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text('Koli Başı',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600])),
                                    Text('$adetPerKoli adet',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple[700])),
                                  ],
                                ),
                                Icon(Icons.close, color: Colors.grey[400]),
                                Column(
                                  children: [
                                    Text('Koli Sayısı',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600])),
                                    Text('$koliSayisi koli',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple[700])),
                                  ],
                                ),
                                Icon(Icons.drag_handle,
                                    color: Colors.grey[400]),
                                Column(
                                  children: [
                                    Text('Toplam',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600])),
                                    Text('$toplamAdet adet',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple[700])),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: notController,
                    decoration: const InputDecoration(
                      labelText: 'Not (Opsiyonel)',
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
              label: const Text('Mix Koli Kaydet'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      ),
    );

    if (sonuc == true) {
      try {
        final koliSayisi = int.tryParse(koliSayisiController.text) ?? 1;

        // Mix beden detaylarını hazırla
        final List<Map<String, dynamic>> mixBedenDetay = [];
        int adetPerKoli = 0;
        for (var beden in bedenListesi) {
          final adet = int.tryParse(bedenAdetControllers[beden]!.text) ?? 0;
          if (adet > 0) {
            mixBedenDetay.add({'beden': beden, 'adet': adet});
            adetPerKoli += adet;
          }
        }

        final toplamAdet = koliSayisi * adetPerKoli;

        // Çeki listesine mix koli ekle
        await supabase.from(DbTables.cekiListesi).insert({
          'model_id': atama['model_id'],
          'beden_kodu': 'MIX',
          'koli_adedi': koliSayisi,
          'adet': toplamAdet,
          'adet_per_koli': adetPerKoli,
          'is_mix_koli': true,
          'mix_beden_detay': mixBedenDetay,
          'paketleme_tarihi': DateTime.now().toIso8601String(),
          'gonderim_durumu': 'bekliyor',
          'notlar': notController.text.isNotEmpty ? notController.text : null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Mix koli oluşturuldu - $koliSayisi koli, $toplamAdet adet'),
              backgroundColor: Colors.purple,
            ),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Mix koli oluşturma hatası: $e');
      }
    }

    // Controller'ları temizle
    koliSayisiController.dispose();
    for (var c in bedenAdetControllers.values) {
      c.dispose();
    }
    notController.dispose();
  }
}
