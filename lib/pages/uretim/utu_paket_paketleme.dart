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
        await _workflowTransitionService.applyTransition(
          tableName: DbTables.paketlemeAtamalari,
          recordId: atama['id'],
          firmaId: TenantManager.instance.requireFirmaId,
          fromStatus: atama['durum']?.toString(),
          toStatus: 'devam_ediyor',
          idempotencyKey: 'paketleme:${atama['id']}:basla',
          extraFields: {
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

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

    await _utuBedenliBitirDialogu(atama);
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _missingColumnName(Object error) {
    if (error is! PostgrestException) return null;
    final message =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'.toLowerCase();

    final withTable = RegExp(
      r'column\s+[a-z0-9_]+\.([a-z0-9_]+)\s+does\s+not\s+exist',
    ).firstMatch(message);
    if (withTable != null) return withTable.group(1);

    final plain = RegExp(
      r'column\s+"?([a-z0-9_]+)"?\s+does\s+not\s+exist',
    ).firstMatch(message);
    return plain?.group(1);
  }

  Future<void> _cekiKaydiEkleEsnek(Map<String, dynamic> values) async {
    final data = Map<String, dynamic>.from(values);
    const opsiyonelAlanSirasi = <String>[
      'mix_beden_detay',
      'is_mix_koli',
      'adet_per_koli',
      'beden_kodu',
      'notlar',
      'koli_no',
      'paketleme_tarihi',
      'gonderim_durumu',
      'firma_id',
    ];

    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        await supabase.from(DbTables.cekiListesi).insert(data);
        return;
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn != null && data.containsKey(missingColumn)) {
          data.remove(missingColumn);
          continue;
        }

        final kaldirilacak = opsiyonelAlanSirasi.firstWhere(
          (alan) => data.containsKey(alan),
          orElse: () => '',
        );
        if (kaldirilacak.isNotEmpty) {
          data.remove(kaldirilacak);
          continue;
        }

        rethrow;
      }
    }

    throw Exception('Çeki listesi kaydı eklenemedi.');
  }

  Future<void> _paketlemeAtamasiEkleEsnek(Map<String, dynamic> values) async {
    final data = Map<String, dynamic>.from(values);
    const opsiyonelAlanSirasi = <String>[
      'tedarikci_id',
      'atanan_kullanici_id',
      'onceki_asama',
      'atama_tarihi',
      'talep_edilen_adet',
      'notlar',
      'firma_id',
      'updated_at',
    ];

    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        await supabase.from(DbTables.paketlemeAtamalari).insert(data);
        return;
      } catch (e) {
        final lower = e.toString().toLowerCase();
        if (lower.contains('check constraint') &&
            (data['durum']?.toString() == 'bekleyen')) {
          data['durum'] = 'atandi';
          continue;
        }

        final missingColumn = _missingColumnName(e);
        if (missingColumn != null && data.containsKey(missingColumn)) {
          data.remove(missingColumn);
          continue;
        }

        final kaldirilacak = opsiyonelAlanSirasi.firstWhere(
          (alan) => data.containsKey(alan),
          orElse: () => '',
        );
        if (kaldirilacak.isNotEmpty) {
          data.remove(kaldirilacak);
          continue;
        }

        rethrow;
      }
    }

    throw Exception('Paketleme ataması eklenemedi.');
  }

  Map<String, int> _parseBedenDagilimi(dynamic raw) {
    if (raw == null) return const <String, int>{};

    if (raw is Map) {
      final result = <String, int>{};
      raw.forEach((key, value) {
        final beden = key.toString().trim().toUpperCase();
        final adet = _toInt(value);
        if (beden.isNotEmpty && adet > 0) {
          result[beden] = adet;
        }
      });
      return result;
    }

    if (raw is List) {
      final result = <String, int>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final beden = (item['beden_kodu'] ?? item['beden'] ?? item['size'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        final adet = _toInt(item['adet'] ?? item['miktar'] ?? item['quantity']);
        if (beden.isNotEmpty && adet > 0) {
          result[beden] = (result[beden] ?? 0) + adet;
        }
      }
      return result;
    }

    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return const <String, int>{};

      var normalized = text;
      if (normalized.startsWith('{') && normalized.endsWith('}')) {
        normalized = normalized.substring(1, normalized.length - 1);
      }

      final result = <String, int>{};
      for (final item in normalized.split(',')) {
        final parts = item.split(':');
        if (parts.length != 2) continue;
        final beden = parts[0]
            .replaceAll('"', '')
            .replaceAll("'", '')
            .trim()
            .toUpperCase();
        final adet = _toInt(
          parts[1]
              .replaceAll('"', '')
              .replaceAll("'", '')
              .replaceAll('}', '')
              .replaceAll('{', '')
              .trim(),
        );
        if (beden.isNotEmpty && adet > 0) {
          result[beden] = adet;
        }
      }
      return result;
    }

    return const <String, int>{};
  }

  Map<String, int> _toplamaUyarliBedenMap(
    Map<String, int> kaynak,
    int hedefToplam,
  ) {
    final temiz = Map<String, int>.from(kaynak)
      ..removeWhere((_, value) => value <= 0);
    if (temiz.isEmpty) return const <String, int>{};

    if (hedefToplam <= 0) return temiz;

    final mevcutToplam = temiz.values.fold<int>(0, (sum, item) => sum + item);
    if (mevcutToplam <= 0 || mevcutToplam == hedefToplam) return temiz;

    final taban = <String, int>{};
    final kalanlar = <Map<String, dynamic>>[];

    for (final entry in temiz.entries) {
      final oransal = (entry.value * hedefToplam) / mevcutToplam;
      final base = oransal.floor();
      taban[entry.key] = base;
      kalanlar.add({'beden': entry.key, 'kalan': oransal - base});
    }

    var dagit = hedefToplam - taban.values.fold<int>(0, (s, v) => s + v);
    kalanlar
        .sort((a, b) => (b['kalan'] as double).compareTo(a['kalan'] as double));

    for (var i = 0; i < dagit; i++) {
      final beden = kalanlar[i % kalanlar.length]['beden'] as String;
      taban[beden] = (taban[beden] ?? 0) + 1;
    }

    taban.removeWhere((_, value) => value <= 0);
    return taban;
  }

  String _bedenMapMetni(Map<String, int> bedenler) {
    if (bedenler.isEmpty) return '-';
    return bedenler.entries.map((e) => '${e.key}:${e.value}').join(' | ');
  }

  Future<void> _utuBedenliBitirDialogu(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;

    const fireKaynakAsamaEtiketleri = <String, String>{
      'dokuma': 'Dokuma',
      'orgu': 'Örgü',
      'konfeksiyon': 'Konfeksiyon',
      'yikama': 'Yıkama',
      'nakis': 'Nakış',
      'ilik_dugme': 'İlik Düğme',
      'utu': 'Ütü',
      'paketleme': 'Paketleme',
      'diger': 'Diğer',
    };
    final fireKaynakAsamaKodlari = fireKaynakAsamaEtiketleri.keys.toList();

    int talepAdet = _toInt(
      atama['talep_edilen_adet'] ?? atama['adet'] ?? model?['adet'],
    );

    var hedefBedenDagilimi = _parseBedenDagilimi(
      atama['beden_detaylari'] ?? atama['beden_dagilimi'] ?? model?['bedenler'],
    );

    if (talepAdet <= 0 && hedefBedenDagilimi.isNotEmpty) {
      talepAdet = hedefBedenDagilimi.values.fold<int>(0, (s, v) => s + v);
    }

    if (hedefBedenDagilimi.isEmpty) {
      hedefBedenDagilimi = {'GENEL': talepAdet > 0 ? talepAdet : 1};
    }

    if (talepAdet <= 0) {
      talepAdet = hedefBedenDagilimi.values.fold<int>(0, (s, v) => s + v);
    }

    hedefBedenDagilimi = _toplamaUyarliBedenMap(hedefBedenDagilimi, talepAdet);

    final tamamControllers = <String, TextEditingController>{};
    final fireControllers = <String, TextEditingController>{};
    final fireKaynakAsamaByBeden = <String, String?>{};

    for (final entry in hedefBedenDagilimi.entries) {
      tamamControllers[entry.key] =
          TextEditingController(text: entry.value.toString());
      fireControllers[entry.key] = TextEditingController(text: '0');
      fireKaynakAsamaByBeden[entry.key] = 'utu';
    }

    final notController = TextEditingController();

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int toplamTamam = 0;
          int toplamFire = 0;
          int toplamKalan = 0;

          for (final beden in hedefBedenDagilimi.keys) {
            final hedef = hedefBedenDagilimi[beden] ?? 0;
            final tamam = _toInt(tamamControllers[beden]?.text);
            final fire = _toInt(fireControllers[beden]?.text);
            final kalan = (hedef - tamam - fire).clamp(0, 999999999);

            toplamTamam += tamam;
            toplamFire += fire;
            toplamKalan += kalan;
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Ütü Tamamla'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.92,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${model?['marka'] ?? '-'} - ${model?['item_no'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Talep Edilen: $talepAdet adet'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Beden Bazlı Tamamlama / Fire',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Beden',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Hedef',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Tamam',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Fire',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Kalan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...hedefBedenDagilimi.keys.map((beden) {
                      final hedef = hedefBedenDagilimi[beden] ?? 0;
                      final tamam = _toInt(tamamControllers[beden]?.text);
                      final fire = _toInt(fireControllers[beden]?.text);
                      final kalan = hedef - tamam - fire;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                beden,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '$hedef',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: tamamControllers[beden],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: fireControllers[beden],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${kalan < 0 ? 0 : kalan}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: kalan < 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text('Tamamlanan: $toplamTamam'),
                          Text('Fire: $toplamFire'),
                          Text('Kalan: $toplamKalan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fire Kaynak Aşaması',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ...hedefBedenDagilimi.keys.where((beden) {
                            final fire = _toInt(fireControllers[beden]?.text);
                            return fire > 0;
                          }).map((beden) {
                            final fire = _toInt(fireControllers[beden]?.text);
                            final mevcutSecim = fireKaynakAsamaByBeden[beden];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 84,
                                    child: Text(
                                      '$beden ($fire)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: (mevcutSecim != null &&
                                              fireKaynakAsamaKodlari
                                                  .contains(mevcutSecim))
                                          ? mevcutSecim
                                          : null,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(),
                                        hintText: 'Aşama seçin',
                                      ),
                                      items: fireKaynakAsamaKodlari
                                          .map(
                                            (kod) => DropdownMenuItem<String>(
                                              value: kod,
                                              child: Text(
                                                fireKaynakAsamaEtiketleri[kod] ??
                                                    kod,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        fireKaynakAsamaByBeden[beden] = value;
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (!hedefBedenDagilimi.keys.any((beden) =>
                              _toInt(fireControllers[beden]?.text) > 0))
                            Text(
                              'Fire girişi yaptığınızda kaynak aşama seçimi açılır.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
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
              ElevatedButton(
                onPressed: () {
                  var satirHataVar = false;
                  for (final beden in hedefBedenDagilimi.keys) {
                    final hedef = hedefBedenDagilimi[beden] ?? 0;
                    final tamam = _toInt(tamamControllers[beden]?.text);
                    final fire = _toInt(fireControllers[beden]?.text);
                    if (tamam < 0 || fire < 0 || (tamam + fire) > hedef) {
                      satirHataVar = true;
                      break;
                    }
                  }

                  if (satirHataVar) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Beden satırlarında Tamam + Fire değeri hedef adedi aşamaz.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final fireAsamaEksik = hedefBedenDagilimi.keys.any((beden) {
                    final fire = _toInt(fireControllers[beden]?.text);
                    if (fire <= 0) return false;
                    final secim = fireKaynakAsamaByBeden[beden]?.trim() ?? '';
                    return secim.isEmpty;
                  });

                  if (fireAsamaEksik) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fire girilen her beden için kaynak aşama seçmelisiniz.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final toplamTamam = hedefBedenDagilimi.keys.fold<int>(
                    0,
                    (sum, beden) => sum + _toInt(tamamControllers[beden]?.text),
                  );
                  final toplamFire = hedefBedenDagilimi.keys.fold<int>(
                    0,
                    (sum, beden) => sum + _toInt(fireControllers[beden]?.text),
                  );

                  if ((toplamTamam + toplamFire) <= 0) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('En az bir beden için adet girmelisiniz.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if ((toplamTamam + toplamFire) > talepAdet) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Toplam Tamam + Fire, talep adedini aşamaz.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Tamamla'),
              ),
            ],
          );
        },
      ),
    );

    if (sonuc == true) {
      try {
        final tamamlananBeden = <String, int>{};
        final fireBeden = <String, int>{};
        final kalanBeden = <String, int>{};

        for (final beden in hedefBedenDagilimi.keys) {
          final hedef = hedefBedenDagilimi[beden] ?? 0;
          final tamam = _toInt(tamamControllers[beden]?.text);
          final fire = _toInt(fireControllers[beden]?.text);
          final kalan = (hedef - tamam - fire).clamp(0, 999999999);

          if (tamam > 0) tamamlananBeden[beden] = tamam;
          if (fire > 0) fireBeden[beden] = fire;
          if (kalan > 0) kalanBeden[beden] = kalan;
        }

        final toplamTamamlanan =
            tamamlananBeden.values.fold<int>(0, (s, v) => s + v);
        final toplamFire = fireBeden.values.fold<int>(0, (s, v) => s + v);
        final kalanAdet = kalanBeden.values.fold<int>(0, (s, v) => s + v);
        final firmaId = TenantManager.instance.requireFirmaId;
        final now = DateTime.now().toIso8601String();

        final fireNotu =
            fireBeden.isNotEmpty ? '[FIRE] ${_bedenMapMetni(fireBeden)}' : '';
        final fireAsamaSatirlari = <String>[];
        for (final entry in fireBeden.entries) {
          final asamaKodu = fireKaynakAsamaByBeden[entry.key]?.trim();
          if (asamaKodu == null || asamaKodu.isEmpty) continue;
          final asamaEtiketi = fireKaynakAsamaEtiketleri[asamaKodu] ?? asamaKodu;
          fireAsamaSatirlari
              .add('${entry.key}:${entry.value}->$asamaEtiketi($asamaKodu)');
        }
        final fireAsamaNotu = fireAsamaSatirlari.isNotEmpty
            ? '[FIRE_KAYNAK] ${fireAsamaSatirlari.join(' | ')}'
            : '';
        final notParcalari = <String>[
          if (notController.text.trim().isNotEmpty) notController.text.trim(),
          if (fireNotu.isNotEmpty) fireNotu,
          if (fireAsamaNotu.isNotEmpty) fireAsamaNotu,
        ];
        final notMetni = notParcalari.join('\n');

        final transitionFields = <String, dynamic>{
          'tamamlanan_adet': toplamTamamlanan,
          'talep_edilen_adet': talepAdet,
          'fire_adet': toplamFire,
          'tamamlama_tarihi': now,
          'updated_at': now,
          if (tamamlananBeden.isNotEmpty) 'beden_detaylari': tamamlananBeden,
          if (notMetni.isNotEmpty) 'notlar': notMetni,
        };

        if (kalanAdet == 0) {
          await _workflowTransitionService.applyTransition(
            tableName: DbTables.utuAtamalari,
            recordId: atama['id'],
            firmaId: firmaId,
            fromStatus: atama['durum']?.toString(),
            toStatus: 'tamamlandi',
            idempotencyKey: 'utu:${atama['id']}:tamamla',
            extraFields: transitionFields,
          );
        } else {
          await _workflowTransitionService.applyTransition(
            tableName: DbTables.utuAtamalari,
            recordId: atama['id'],
            firmaId: firmaId,
            fromStatus: atama['durum']?.toString(),
            toStatus: 'kismi_tamamlandi',
            idempotencyKey: 'utu:${atama['id']}:kismi_tamamla',
            extraFields: transitionFields,
          );

          await supabase.from(DbTables.utuAtamalari).insert({
            'model_id': atama['model_id'],
            'tedarikci_id': atama['tedarikci_id'],
            if (atama['atanan_kullanici_id'] != null)
              'atanan_kullanici_id': atama['atanan_kullanici_id'],
            'talep_edilen_adet': kalanAdet,
            'adet': kalanAdet,
            'durum': 'atandi',
            'atama_tarihi': now,
            if (kalanBeden.isNotEmpty) 'beden_detaylari': kalanBeden,
            'notlar': 'Kısmi tamamlamadan devam - Kalan adet: $kalanAdet',
            'firma_id': firmaId,
          });
        }

        if (toplamTamamlanan > 0) {
          await _paketlemeyeOtomatikAta(atama, toplamTamamlanan);
        }

        if (mounted) {
          final mesajParcalari = <String>[
            '$toplamTamamlanan adet tamamlandı',
            if (toplamFire > 0) '$toplamFire adet fire işlendi',
            if (kalanAdet > 0) '$kalanAdet adet işlemde devam ediyor',
          ];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${mesajParcalari.join(', ')}'),
              backgroundColor: Colors.green,
            ),
          );
          _verileriYukle();
        }
      } catch (e) {
        _hataGoster('Tamamlama hatası: $e');
      }
    }

    for (final c in tamamControllers.values) {
      c.dispose();
    }
    for (final c in fireControllers.values) {
      c.dispose();
    }
    notController.dispose();
  }

  // ===== ÜTÜ TAMAMLANINCA PAKETLEMEYİ OTOMATİK AT =====
  Future<void> _paketlemeyeOtomatikAta(
      Map<String, dynamic> utuAtama, int tamamlananAdet) async {
    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      var useFirmaFilter = true;

      // Aynı model için paketleme ataması var mı kontrol et
      List<dynamic> mevcutPaketlemeList = const [];
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          var query = supabase
              .from(DbTables.paketlemeAtamalari)
              .select('id, adet, durum')
              .eq('model_id', utuAtama['model_id'])
              .neq('durum', 'tamamlandi');
          if (useFirmaFilter) {
            query = query.eq('firma_id', firmaId);
          }

          mevcutPaketlemeList = await query.order('id', ascending: false).limit(1);
          break;
        } catch (e) {
          final missingColumn = _missingColumnName(e);
          if (missingColumn == 'firma_id' && useFirmaFilter) {
            useFirmaFilter = false;
            continue;
          }
          rethrow;
        }
      }

      final mevcutPaketleme =
          List<Map<String, dynamic>>.from(mevcutPaketlemeList).isEmpty
              ? null
              : List<Map<String, dynamic>>.from(mevcutPaketlemeList).first;

      if (mevcutPaketleme != null) {
        // Mevcut paketleme atamasının adetini artır
        final yeniAdet = (mevcutPaketleme['adet'] ?? 0) + tamamlananAdet;
        final updateData = {
          'adet': yeniAdet,
          'talep_edilen_adet': yeniAdet,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await supabase.from(DbTables.paketlemeAtamalari).update(updateData)
            .eq('id', mevcutPaketleme['id']).eq('firma_id', firmaId);
        } catch (e) {
          final missingColumn = _missingColumnName(e);
          if (missingColumn != null && updateData.containsKey(missingColumn)) {
            updateData.remove(missingColumn);
          }
          await supabase.from(DbTables.paketlemeAtamalari).update(updateData)
            .eq('id', mevcutPaketleme['id']);
        }

        debugPrint('Mevcut paketleme atamasına $tamamlananAdet adet eklendi');
      } else {
        // Yeni paketleme ataması oluştur
        await _paketlemeAtamasiEkleEsnek({
          'model_id': utuAtama['model_id'],
          'tedarikci_id': utuAtama['tedarikci_id'],
          'atanan_kullanici_id':
              utuAtama['atanan_kullanici_id'] ?? currentUserId,
          'adet': tamamlananAdet,
          'talep_edilen_adet': tamamlananAdet,
          'durum': 'bekleyen',
          'onceki_asama': 'utu',
          'atama_tarihi': DateTime.now().toIso8601String(),
          'firma_id': firmaId,
        });

        debugPrint('Yeni paketleme ataması oluşturuldu: $tamamlananAdet adet');
      }
    } catch (e) {
      debugPrint('Paketleme ataması oluşturma hatası: $e');
      // Fail-safe: Paketleme ataması açılamazsa modeli doğrudan çeki listesine ilerlet.
      try {
        await _cekiKaydiEkleEsnek({
          'model_id': utuAtama['model_id'],
          'beden_kodu': 'GENEL',
          'koli_adedi': 1,
          'adet': tamamlananAdet,
          'adet_per_koli': tamamlananAdet,
          'paketleme_tarihi': DateTime.now().toIso8601String(),
          'gonderim_durumu': 'bekliyor',
          'firma_id': TenantManager.instance.requireFirmaId,
          'notlar':
              '[AUTO-UTU] Paketleme ataması açılamadı, kayıt otomatik çeki listesine aktarıldı.',
        });
        debugPrint('✅ Fail-safe çeki kaydı oluşturuldu (Ütü -> Çeki).');
      } catch (cekiError) {
        debugPrint('❌ Fail-safe çeki oluşturma hatası: $cekiError');
      }
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
          await _workflowTransitionService.applyTransition(
            tableName: DbTables.paketlemeAtamalari,
            recordId: atama['id'],
            firmaId: TenantManager.instance.requireFirmaId,
            fromStatus: atama['durum']?.toString(),
            toStatus: 'tamamlandi',
            idempotencyKey: 'paketleme:${atama['id']}:tamamla',
            extraFields: {
              'tamamlanan_adet': toplamAdet,
              'tamamlama_tarihi': DateTime.now().toIso8601String(),
              'notlar': notController.text.isNotEmpty ? notController.text : null,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        } else if (kalanAdet > 0) {
          // Kısmi tamamlandı - işlemde kalmalı
          await _workflowTransitionService.applyTransition(
            tableName: DbTables.paketlemeAtamalari,
            recordId: atama['id'],
            firmaId: TenantManager.instance.requireFirmaId,
            fromStatus: atama['durum']?.toString(),
            toStatus: 'kismi_tamamlandi',
            idempotencyKey: 'paketleme:${atama['id']}:kismi_tamamla',
            extraFields: {
              'tamamlanan_adet': toplamAdet,
              'tamamlama_tarihi': DateTime.now().toIso8601String(),
              'notlar': notController.text.isNotEmpty ? notController.text : null,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );

          // Kalan adet için yeni atama oluştur
          await supabase.from(DbTables.paketlemeAtamalari).insert({
            'model_id': atama['model_id'],
            'talep_edilen_adet': kalanAdet,
            'durum': 'bekleyen',
            'baslangic_tarihi': DateTime.now().toIso8601String(),
            'notlar': 'Kalan adet (Önceki atama: ${atama['id']})',
            'firma_id': TenantManager.instance.requireFirmaId,
          });
        } else {
          // Fazla tamamlandı
          await _workflowTransitionService.applyTransition(
            tableName: DbTables.paketlemeAtamalari,
            recordId: atama['id'],
            firmaId: TenantManager.instance.requireFirmaId,
            fromStatus: atama['durum']?.toString(),
            toStatus: 'tamamlandi',
            idempotencyKey: 'paketleme:${atama['id']}:fazla_tamamla',
            extraFields: {
              'tamamlanan_adet': toplamAdet,
              'tamamlama_tarihi': DateTime.now().toIso8601String(),
              'notlar': notController.text.isNotEmpty ? notController.text : null,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        }

        // Çeki listesine ekle (beden bazlı)
        for (var beden in bedenDetaylari) {
          if (beden['adet'] > 0) {
            try {
              await _cekiKaydiEkleEsnek({
                'model_id': atama['model_id'],
                'beden_kodu': beden['beden_kodu'],
                'koli_adedi': beden['koli_sayisi'],
                'adet': beden['adet'],
                'adet_per_koli': beden['adet_per_koli'],
                'paketleme_tarihi': DateTime.now().toIso8601String(),
                'gonderim_durumu': 'bekliyor',
                'firma_id': TenantManager.instance.requireFirmaId,
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
        await _cekiKaydiEkleEsnek({
          'model_id': atama['model_id'],
          'beden_kodu': 'MIX',
          'koli_adedi': koliSayisi,
          'adet': toplamAdet,
          'adet_per_koli': adetPerKoli,
          'is_mix_koli': true,
          'mix_beden_detay': mixBedenDetay,
          'paketleme_tarihi': DateTime.now().toIso8601String(),
          'gonderim_durumu': 'bekliyor',
          'firma_id': TenantManager.instance.requireFirmaId,
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
