// ignore_for_file: invalid_use_of_protected_member
part of 'sevkiyat_panel.dart';

/// Sevkiyat panel - widget builders, dialoglar ve aksiyonlar
extension _WidgetsExt on _SevkiyatPanelState {
  Widget _buildSevkListesi(List<Map<String, dynamic>> liste, String tip) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tip == 'bekleyen'
                  ? Icons.inbox
                  : tip == 'devam'
                      ? Icons.local_shipping
                      : Icons.check_circle,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              tip == 'bekleyen'
                  ? 'Sevk bekleyen ürün yok'
                  : tip == 'devam'
                      ? 'Sevk edilen ürün yok'
                      : 'Tamamlanan sevk yok',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (context, index) => _buildSevkCard(liste[index], tip),
      ),
    );
  }

  Widget _buildSevkCard(Map<String, dynamic> sevk, String tip) {
    final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = sevk['durum'] as String?;
    final adet =
        sevk['adet'] ?? sevk['talep_edilen_adet'] ?? model['adet'] ?? 0;
    final bedenDetayi = _parseBedenDetayi(sevk['beden_detaylari']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2,
                      color: Colors.indigo.shade600, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${model['marka'] ?? 'Bilinmiyor'} - ${model['item_no'] ?? 'N/A'}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Kalite Kontrolden Geldi',
                        style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _buildDurumBadge(durum),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Bilgiler
            _buildBilgiSatiri('Renk', model['renk']),
            _buildBilgiSatiri('Sevk Edilecek Adet', '$adet adet', isBold: true),
            if (bedenDetayi.isNotEmpty)
              _buildBilgiSatiri(
                'Beden Dağılımı',
                _bedenDagilimiMetni(bedenDetayi),
                textColor: Colors.indigo.shade700,
              ),

            if (model['termin_tarihi'] != null)
              _buildBilgiSatiri(
                'Termin',
                DateFormat('dd.MM.yyyy')
                    .format(DateTime.parse(model['termin_tarihi'])),
                textColor: Colors.orange,
              ),

            if (sevk['atama_tarihi'] != null)
              _buildBilgiSatiri(
                'Sevk Talebi',
                DateFormat('dd.MM.yyyy HH:mm')
                    .format(DateTime.parse(sevk['atama_tarihi'])),
              ),

            if (sevk['hedef_asama'] != null)
              _buildBilgiSatiri('Hedef Aşama', sevk['hedef_asama'],
                  textColor: Colors.blue),

            if (sevk['notlar'] != null && sevk['notlar'].toString().isNotEmpty)
              _buildBilgiSatiri('Notlar', sevk['notlar']),

            // Aksiyon butonları
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildAksiyonButonlari(sevk, tip),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiSatiri(String label, String? value,
      {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(String? durum) {
    Color renk;
    String text;

    switch (durum) {
      case 'atandi':
      case 'beklemede':
        renk = Colors.orange;
        text = 'Sevk Bekliyor';
        break;
      case 'baslandi':
      case 'sevk_ediliyor':
        renk = Colors.blue;
        text = 'Sevk Ediliyor';
        break;
      case 'tamamlandi':
      case 'sevk_edildi':
        renk = Colors.green;
        text = 'Tamamlandı';
        break;
      default:
        renk = Colors.grey;
        text = durum ?? 'Bilinmiyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildAksiyonButonlari(Map<String, dynamic> sevk, String tip) {
    if (tip == 'bekleyen') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDetayDialog(sevk),
              icon: const Icon(Icons.info_outline),
              label: const Text('Detay'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _showSevkDialog(sevk),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Sevk Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (tip == 'devam') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDetayDialog(sevk),
              icon: const Icon(Icons.info_outline),
              label: const Text('Detay'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _sevkTamamla(sevk),
              icon: const Icon(Icons.check),
              label: const Text('Tamamla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _showDetayDialog(sevk),
        icon: const Icon(Icons.info_outline),
        label: const Text('Detay Görüntüle'),
      );
    }
  }

  void _showAramaDialog() {
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
          onChanged: (value) {
            setState(() => aramaMetni = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _aramaController.clear();
              setState(() => aramaMetni = '');
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }

  String _normalizeAsamaKodu(String? value) {
    final raw = (value ?? '')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .trim();

    if (raw.contains('dokuma')) return 'dokuma';
    if (raw.contains('nakis')) return 'nakis';
    if (raw.contains('konfeksiyon')) return 'konfeksiyon';
    if (raw.contains('yikama')) return 'yikama';
    if (raw.contains('utu')) return 'utu';
    if (raw.contains('ilik') || raw.contains('dugme')) return 'ilik_dugme';
    if (raw.contains('paket')) return 'paketleme';
    if (raw.contains('kalite')) return 'kalite_kontrol';
    if (raw.contains('depo')) return 'depo';
    if (raw.contains('sevkiyat')) return 'sevkiyat';

    return raw.replaceAll(' ', '_');
  }

  String? _kaynakAsamaKodu(Map<String, dynamic> sevk) {
    final onceki = sevk['onceki_asama']?.toString();
    if (onceki != null && onceki.trim().isNotEmpty) {
      return _normalizeAsamaKodu(onceki);
    }

    final kaynakTablo = sevk['kaynak_tablo']?.toString();
    if (kaynakTablo == null) return null;
    if (kaynakTablo == DbTables.dokumaAtamalari) return 'dokuma';
    if (kaynakTablo == DbTables.nakisAtamalari) return 'nakis';
    if (kaynakTablo == DbTables.konfeksiyonAtamalari) return 'konfeksiyon';
    if (kaynakTablo == DbTables.yikamaAtamalari) return 'yikama';
    if (kaynakTablo == DbTables.utuAtamalari) return 'utu';
    if (kaynakTablo == DbTables.ilikDugmeAtamalari) return 'ilik_dugme';
    if (kaynakTablo == DbTables.paketlemeAtamalari) return 'paketleme';
    if (kaynakTablo == DbTables.kaliteKontrolAtamalari) return 'kalite_kontrol';
    return null;
  }

  String? _siradakiHedefAsama(String? kaynakAsamaKodu) {
    switch (kaynakAsamaKodu) {
      case 'dokuma':
        return 'nakis';
      case 'nakis':
        return 'konfeksiyon';
      case 'konfeksiyon':
        return 'yikama';
      case 'yikama':
        return 'utu';
      case 'utu':
        return 'ilik_dugme';
      case 'ilik_dugme':
      case 'paketleme':
      case 'kalite_kontrol':
        return 'depo';
      default:
        return null;
    }
  }

  bool _hedefAsamaSerbestSecim(Map<String, dynamic> sevk) {
    if (sevk['kalite_kontrol_id'] != null) return true;

    final kaynakTablo = sevk['kaynak_tablo']?.toString();
    if (kaynakTablo == DbTables.sevkiyatKayitlari) return true;

    final kaynakAsama = _kaynakAsamaKodu(sevk);
    return kaynakAsama == 'kalite_kontrol';
  }

  List<Map<String, dynamic>> _izinliHedefAsamalar(Map<String, dynamic> sevk) {
    if (_hedefAsamaSerbestSecim(sevk)) {
      return hedefAsamalar;
    }

    final kaynak = _kaynakAsamaKodu(sevk);
    final siradaki = _siradakiHedefAsama(kaynak);
    if (siradaki == null) return hedefAsamalar;

    final filtreli = hedefAsamalar.where((a) => a['key'] == siradaki).toList();
    return filtreli.isEmpty ? hedefAsamalar : filtreli;
  }

  String _temizSevkNotu(dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return '-';

    final temiz = text
        .replaceAll(RegExp(r'\[(?:IDEMP|REWORK):[^\]]+\]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(' \n', '\n')
        .trim();

    return temiz.isEmpty ? '-' : temiz;
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

  Map<String, int> _parseBedenDetayi(dynamic raw) {
    dynamic value = raw;
    if (value == null) return const <String, int>{};

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const <String, int>{};
      try {
        value = jsonDecode(text);
      } catch (_) {
        return const <String, int>{};
      }
    }

    if (value is Map) {
      final result = <String, int>{};
      value.forEach((key, val) {
        final beden = key.toString().trim().toUpperCase();
        final adet = (val as num?)?.toInt() ?? int.tryParse('$val') ?? 0;
        if (beden.isNotEmpty && adet > 0) {
          result[beden] = adet;
        }
      });
      return _siraliBedenMap(result);
    }

    if (value is List) {
      final result = <String, int>{};
      for (final item in value) {
        if (item is! Map) continue;
        final beden = (item['beden_kodu'] ??
                item['beden'] ??
                item['size'] ??
                item['label'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();
        final adet = (item['adet'] as num?)?.toInt() ??
            (item['miktar'] as num?)?.toInt() ??
            (item['quantity'] as num?)?.toInt() ??
            int.tryParse('${item['value']}') ??
            0;
        if (beden.isNotEmpty && adet > 0) {
          result[beden] = (result[beden] ?? 0) + adet;
        }
      }
      return _siraliBedenMap(result);
    }

    return const <String, int>{};
  }

  int _bedenSiraSkoru(String beden) {
    const standart = <String>[
      'XXS',
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      '3XL',
      '4XL',
      '5XL',
    ];

    final key = beden.toUpperCase();
    final index = standart.indexOf(key);
    return index >= 0 ? index : (100 + (key.isEmpty ? 0 : key.codeUnitAt(0)));
  }

  Map<String, int> _siraliBedenMap(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((a, b) {
        final sa = _bedenSiraSkoru(a.key);
        final sb = _bedenSiraSkoru(b.key);
        if (sa != sb) return sa.compareTo(sb);
        return a.key.compareTo(b.key);
      });
    return Map<String, int>.fromEntries(entries);
  }

  int _toplamBedenAdedi(Map<String, int> map) {
    return map.values.fold<int>(0, (sum, val) => sum + val);
  }

  Map<String, int> _oransalBedenDagitimi(
    Map<String, int> kaynak,
    int hedefToplam,
  ) {
    final temiz = kaynak.map((key, value) => MapEntry(key, value < 0 ? 0 : value))
      ..removeWhere((_, value) => value <= 0);
    if (temiz.isEmpty) return const <String, int>{};
    if (hedefToplam <= 0) return _siraliBedenMap(temiz);

    final mevcutToplam = _toplamBedenAdedi(temiz);
    if (mevcutToplam == hedefToplam) return _siraliBedenMap(temiz);
    if (mevcutToplam <= 0) return const <String, int>{};

    final tabanlar = <String, int>{};
    final kalanlar = <Map<String, dynamic>>[];
    for (final entry in temiz.entries) {
      final oransal = (entry.value * hedefToplam) / mevcutToplam;
      final taban = oransal.floor();
      tabanlar[entry.key] = taban;
      kalanlar.add({'beden': entry.key, 'kalan': oransal - taban});
    }

    var dagitilacak = hedefToplam - _toplamBedenAdedi(tabanlar);
    kalanlar.sort((a, b) =>
        (b['kalan'] as double).compareTo(a['kalan'] as double));

    for (var i = 0; i < dagitilacak; i++) {
      final beden = kalanlar[i % kalanlar.length]['beden'] as String;
      tabanlar[beden] = (tabanlar[beden] ?? 0) + 1;
    }

    tabanlar.removeWhere((_, value) => value <= 0);
    return _siraliBedenMap(tabanlar);
  }

  String? _asamaBedenTakipTablosu(String? asamaKodu) {
    switch (_normalizeAsamaKodu(asamaKodu)) {
      case 'dokuma':
        return 'dokuma_beden_takip';
      case 'nakis':
        return 'nakis_beden_takip';
      case 'konfeksiyon':
        return 'konfeksiyon_beden_takip';
      case 'yikama':
        return 'yikama_beden_takip';
      case 'utu':
        return 'utu_beden_takip';
      case 'ilik_dugme':
        return 'ilik_dugme_beden_takip';
      case 'paketleme':
        return 'paketleme_beden_takip';
      default:
        return null;
    }
  }

  Future<Map<String, int>> _asamaBedenGerceklesenAdetleriGetir({
    required String modelId,
    required String? asamaKodu,
  }) async {
    final tablo = _asamaBedenTakipTablosu(asamaKodu);
    if (tablo == null) return const <String, int>{};

    var useFirmaFilter = true;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        var query = supabase.from(tablo).select('*').eq('model_id', modelId);
        if (useFirmaFilter) {
          query = query.eq('firma_id', TenantManager.instance.requireFirmaId);
        }

        final response = await query;
        final sonuc = <String, int>{};

        for (final row in List<Map<String, dynamic>>.from(response)) {
          final beden =
              (row['beden_kodu'] ?? '').toString().trim().toUpperCase();
          if (beden.isEmpty) continue;

          final uretilen = (row['uretilen_adet'] as num?)?.toInt() ??
              int.tryParse('${row['uretilen_adet']}') ??
              0;
          final fire = (row['fire_adet'] as num?)?.toInt() ??
              int.tryParse('${row['fire_adet']}') ??
              0;
          final kabul = (row['kabul_edilen_adet'] as num?)?.toInt() ??
              int.tryParse('${row['kabul_edilen_adet']}') ??
              0;
          final hedef = (row['hedef_adet'] as num?)?.toInt() ??
              int.tryParse('${row['hedef_adet']}') ??
              0;

          final net = uretilen > 0
              ? (uretilen - fire).clamp(0, 999999999).toInt()
              : (kabul > 0 ? kabul : hedef);

          if (net <= 0) continue;
          sonuc[beden] = (sonuc[beden] ?? 0) + net;
        }

        return _siraliBedenMap(sonuc);
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn == 'firma_id' && useFirmaFilter) {
          useFirmaFilter = false;
          continue;
        }
        break;
      }
    }

    return const <String, int>{};
  }

  Future<Map<String, int>> _kaliteKaynakliBedenDagilimiGetir({
    required Map<String, dynamic> sevk,
    required String modelId,
  }) async {
    final kaliteId = sevk['kalite_kontrol_id'];
    if (kaliteId == null) return const <String, int>{};

    var useFirmaFilter = true;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        var query = supabase
            .from(DbTables.kaliteKontrolAtamalari)
            .select('*')
            .eq('id', kaliteId);
        if (useFirmaFilter) {
          query = query.eq('firma_id', TenantManager.instance.requireFirmaId);
        }

        final kalite = await query.maybeSingle();
        if (kalite == null) return const <String, int>{};

        final kayitli = _parseBedenDetayi(kalite['beden_detaylari']);
        if (kayitli.isNotEmpty) {
          return _siraliBedenMap(kayitli);
        }

        final oncekiAsamaKodu = _normalizeAsamaKodu(
          kalite['onceki_asama']?.toString(),
        );
        final oncekiAsama = await _asamaBedenGerceklesenAdetleriGetir(
          modelId: modelId,
          asamaKodu: oncekiAsamaKodu,
        );
        if (oncekiAsama.isNotEmpty) {
          return _siraliBedenMap(oncekiAsama);
        }

        return const <String, int>{};
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn == 'firma_id' && useFirmaFilter) {
          useFirmaFilter = false;
          continue;
        }
        break;
      }
    }

    return const <String, int>{};
  }

  Map<String, int> _kalanBedenDagilimi(
    Map<String, int> mevcut,
    Map<String, int> sevk,
  ) {
    final result = <String, int>{};
    final tumBedenler = <String>{...mevcut.keys, ...sevk.keys};

    for (final beden in tumBedenler) {
      final kalan = (mevcut[beden] ?? 0) - (sevk[beden] ?? 0);
      if (kalan > 0) {
        result[beden] = kalan;
      }
    }

    return _siraliBedenMap(result);
  }

  String _bedenDagilimiMetni(Map<String, int> bedenler) {
    if (bedenler.isEmpty) return '-';
    return bedenler.entries.map((entry) => '${entry.key}:${entry.value}').join(' | ');
  }

  Future<Map<String, int>> _varsayilanSevkBedenDagilimi(
    Map<String, dynamic> sevk,
    int toplamAdet,
  ) async {
    final kayitli = _parseBedenDetayi(
      sevk['beden_detaylari'] ?? sevk['beden_dagilimi'],
    );
    if (kayitli.isNotEmpty) {
      return _siraliBedenMap(kayitli);
    }

    final modelId = sevk['model_id']?.toString();
    if (modelId == null || modelId.isEmpty) return const <String, int>{};

    final kaliteDagilimi = await _kaliteKaynakliBedenDagilimiGetir(
      sevk: sevk,
      modelId: modelId,
    );
    if (kaliteDagilimi.isNotEmpty) {
      return _siraliBedenMap(kaliteDagilimi);
    }

    final oncekiAsamaDagilimi = await _asamaBedenGerceklesenAdetleriGetir(
      modelId: modelId,
      asamaKodu: sevk['onceki_asama']?.toString(),
    );
    if (oncekiAsamaDagilimi.isNotEmpty) {
      return _siraliBedenMap(oncekiAsamaDagilimi);
    }

    try {
      final response = await supabase
          .from(DbTables.modelBedenDagilimi)
          .select('beden_kodu, siparis_adedi')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('model_id', modelId);

      final dagilim = <String, int>{};
      for (final row in List<Map<String, dynamic>>.from(response)) {
        final beden = (row['beden_kodu'] ?? '').toString().trim().toUpperCase();
        final adet = (row['siparis_adedi'] as num?)?.toInt() ??
            int.tryParse('${row['siparis_adedi']}') ??
            0;
        if (beden.isNotEmpty && adet > 0) {
          dagilim[beden] = adet;
        }
      }

      if (dagilim.isNotEmpty) {
        return _oransalBedenDagitimi(dagilim, toplamAdet);
      }
    } catch (_) {}

    return const <String, int>{};
  }

  Future<void> _opsiyonelBedenDetayiGuncelle({
    required dynamic sevkiyatId,
    required String firmaId,
    required Map<String, int> bedenDetayi,
  }) async {
    try {
      await supabase
          .from(DbTables.sevkiyatKayitlari)
          .update({
            'beden_detaylari': bedenDetayi,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sevkiyatId)
          .eq('firma_id', firmaId);
    } catch (e) {
      final missing = _missingColumnName(e);
      if (missing == 'beden_detaylari') {
        return;
      }
      try {
        await supabase
            .from(DbTables.sevkiyatKayitlari)
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', sevkiyatId);
      } catch (_) {}
    }
  }

  Future<void> _esnekSevkiyatDetayInsert(Map<String, dynamic> values) async {
    final data = Map<String, dynamic>.from(values);
    Object? sonHata;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await supabase.from(DbTables.sevkiyatDetaylari).insert(data);
        return;
      } catch (e) {
        sonHata = e;
        final missing = _missingColumnName(e);
        if (missing != null && data.containsKey(missing)) {
          data.remove(missing);
          continue;
        }
        if (data.containsKey('beden_detaylari')) {
          data.remove('beden_detaylari');
          continue;
        }
        break;
      }
    }

    throw Exception('sevkiyat_detaylari insert başarısız: $sonHata');
  }

  Future<void> _showSevkDialog(Map<String, dynamic> sevk) async {
    final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final mevcutAdetRaw =
      sevk['adet'] ?? sevk['talep_edilen_adet'] ?? model['adet'] ?? 0;
    var toplamMevcutAdet = (mevcutAdetRaw as num?)?.toInt() ??
      int.tryParse('$mevcutAdetRaw') ??
      0;
    final mevcutBedenAdetleri =
        await _varsayilanSevkBedenDagilimi(sevk, toplamMevcutAdet);
    final bedenToplam = _toplamBedenAdedi(mevcutBedenAdetleri);
    if (bedenToplam > 0) {
      toplamMevcutAdet = bedenToplam;
    }
    if (!mounted) return;

    final izinliAsamalar = _izinliHedefAsamalar(sevk);
    final adetController =
        TextEditingController(text: toplamMevcutAdet.toString());
    final notlarController = TextEditingController();
    final bedenControllers = {
      for (final entry in mevcutBedenAdetleri.entries)
        entry.key: TextEditingController(text: entry.value.toString()),
    };
    String? secilenHedefAsama;
    Map<String, dynamic>? secilenTedarikci;
    List<Map<String, dynamic>> tedarikciler = [];
    bool tedarikcilerYukleniyor = false;
    var seciliBedenToplam = _toplamBedenAdedi(mevcutBedenAdetleri);

    // Dış atölye gerektiren aşamalar (firma seçimi gerektirenler)
    final disAtolyeAsamalar = [
      'yikama',
      'nakis',
      'konfeksiyon',
      'dokuma',
      'utu',
      'ilik_dugme'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              const Text('Sevk Et'),
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
                      Text(
                        '${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (model['renk'] != null) Text('Renk: ${model['renk']}'),
                      Text('Mevcut Adet: $toplamMevcutAdet'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (mevcutBedenAdetleri.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Beden Bazlı Sevk Adetleri',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...mevcutBedenAdetleri.entries.map((entry) {
                          final beden = entry.key;
                          final maxAdet = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    beden,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: bedenControllers[beden],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      helperText: 'Maks: $maxAdet',
                                    ),
                                    onChanged: (_) {
                                      var toplam = 0;
                                      for (final ctrl in bedenControllers.values) {
                                        toplam +=
                                            int.tryParse(ctrl.text.trim()) ?? 0;
                                      }
                                      setDialogState(() {
                                        seciliBedenToplam = toplam;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        Text(
                          'Toplam Sevk: $seciliBedenToplam / $toplamMevcutAdet',
                          style: TextStyle(
                            color: seciliBedenToplam > toplamMevcutAdet
                                ? Colors.red
                                : Colors.indigo.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: adetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Sevk Edilecek Adet',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.numbers),
                      helperText: 'Maksimum: $toplamMevcutAdet adet',
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Hedef aşama seçimi
                const Text(
                  'Hedef Aşama Seçin:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: izinliAsamalar.map((asama) {
                    final isSelected = secilenHedefAsama == asama['key'];
                    return InkWell(
                      onTap: () async {
                        setDialogState(() {
                          secilenHedefAsama = asama['key'];
                          secilenTedarikci = null;
                          tedarikciler = [];
                        });

                        // Dış atölye aşaması ise tedarikcileri yükle
                        if (disAtolyeAsamalar.contains(asama['key'])) {
                          setDialogState(() => tedarikcilerYukleniyor = true);
                          try {
                            // Faaliyet değerini belirle - birden fazla varyasyonu ara
                            if (asama['key'] == 'yikama') {
                            } else if (asama['key'] == 'nakis') {}

                            // Tüm tedarikcileri çek ve faaliyet içerenleri filtrele
                            final response = await supabase
                                .from(DbTables.tedarikciler)
                                .select('id, sirket, faaliyet');

                            final tumTedarikciler =
                                List<Map<String, dynamic>>.from(response);

                            // Faaliyet alanında arama yap (case-insensitive)
                            final filtrelenmis = tumTedarikciler.where((t) {
                              final faaliyet = (t['faaliyet'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final asamaKey = asama['key'];
                              if (asamaKey == 'yikama') {
                                return faaliyet.contains('yikama') ||
                                    faaliyet.contains('yıkama');
                              } else if (asamaKey == 'nakis') {
                                return faaliyet.contains('nakis') ||
                                    faaliyet.contains('nakış');
                              } else if (asamaKey == 'konfeksiyon') {
                                return faaliyet.contains('konfeksiyon') ||
                                    faaliyet.contains('dikim');
                              } else if (asamaKey == 'dokuma') {
                                return faaliyet.contains('dokuma') ||
                                    faaliyet.contains('orgu') ||
                                    faaliyet.contains('örgü');
                              } else if (asamaKey == 'utu') {
                                return faaliyet.contains('utu') ||
                                    faaliyet.contains('ütü');
                              } else if (asamaKey == 'ilik_dugme') {
                                return faaliyet.contains('ilik') ||
                                    faaliyet.contains('dugme') ||
                                    faaliyet.contains('düğme');
                              }
                              return false;
                            }).toList();

                            setDialogState(() {
                              tedarikciler = filtrelenmis;
                              tedarikcilerYukleniyor = false;
                            });
                            debugPrint(
                                '📦 ${asama['key']} tedarikcileri: ${tedarikciler.length} (toplam: ${tumTedarikciler.length})');

                            // Debug: Tüm faaliyetleri listele
                            for (var t in tumTedarikciler) {
                              debugPrint(
                                  '   - ${t['sirket']}: ${t['faaliyet']}');
                            }
                          } catch (e) {
                            debugPrint('❌ Tedarikci yükleme hatası: $e');
                            setDialogState(
                                () => tedarikcilerYukleniyor = false);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (asama['color'] as Color)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (asama['color'] as Color)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              asama['icon'] as IconData,
                              color: isSelected
                                  ? Colors.white
                                  : (asama['color'] as Color),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              asama['name'] as String,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Dış atölye seçilmişse tedarikci seçimi göster
                if (secilenHedefAsama != null &&
                    disAtolyeAsamalar.contains(secilenHedefAsama)) ...[
                  const Text(
                    'Tedarikci/Firma Seçin:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (tedarikcilerYukleniyor)
                    const LoadingWidget()
                  else if (tedarikciler.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu aşama için kayıtlı tedarikci bulunamadı.',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: tedarikciler.map((tedarikci) {
                          final isSelected =
                              secilenTedarikci?['id'] == tedarikci['id'];
                          return InkWell(
                            onTap: () {
                              setDialogState(
                                  () => secilenTedarikci = tedarikci);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? Colors.indigo.shade50 : null,
                                border: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? Colors.indigo
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tedarikci['sirket'] ?? 'Bilinmiyor',
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // Notlar
                TextField(
                  controller: notlarController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (İsteğe Bağlı)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
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
            ElevatedButton.icon(
              onPressed: secilenHedefAsama == null
                  ? null
                  : () async {
                      final seciliBedenler = <String, int>{};
                      int sevkAdet;

                      if (mevcutBedenAdetleri.isNotEmpty) {
                        for (final entry in mevcutBedenAdetleri.entries) {
                          final beden = entry.key;
                          final maxAdet = entry.value;
                          final girilen =
                              int.tryParse(bedenControllers[beden]!.text.trim()) ??
                                  0;

                          if (girilen < 0) {
                            context.showErrorSnackBar(
                                '$beden için negatif adet girilemez');
                            return;
                          }

                          if (girilen > maxAdet) {
                            context.showErrorSnackBar(
                                '$beden bedeni için adet ($girilen), mevcut adedi ($maxAdet) geçemez');
                            return;
                          }

                          if (girilen > 0) {
                            seciliBedenler[beden] = girilen;
                          }
                        }
                        sevkAdet = _toplamBedenAdedi(seciliBedenler);
                      } else {
                        sevkAdet = int.tryParse(adetController.text) ?? 0;
                      }

                      if (sevkAdet <= 0) {
                        context.showErrorSnackBar('Geçerli bir adet giriniz');
                        return;
                      }

                      if (sevkAdet > toplamMevcutAdet) {
                        context.showErrorSnackBar(
                            'Sevk adeti mevcut adetten ($toplamMevcutAdet) fazla olamaz');
                        return;
                      }

                      // Dış atölye için tedarikci kontrolü
                      if (disAtolyeAsamalar.contains(secilenHedefAsama) &&
                          secilenTedarikci == null) {
                        context.showErrorSnackBar(
                            'Lütfen bir tedarikci/firma seçin');
                        return;
                      }

                      final izinliKodlar =
                          izinliAsamalar.map((a) => a['key']).toSet();
                      if (!izinliKodlar.contains(secilenHedefAsama)) {
                        context.showErrorSnackBar(
                            'Hedef aşama sırası geçersiz. Lütfen önerilen sırayı kullanın.');
                        return;
                      }

                      await _sevkYap(
                        sevk: sevk,
                        hedefAsama: secilenHedefAsama!,
                        adet: sevkAdet,
                        notlar: notlarController.text,
                        tedarikciId: secilenTedarikci?['id'],
                        bedenDetaylari:
                            seciliBedenler.isEmpty ? null : seciliBedenler,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              icon: const Icon(Icons.send),
              label: const Text('Sevk Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sevkYap({
    required Map<String, dynamic> sevk,
    required String hedefAsama,
    required int adet,
    String? notlar,
    int? tedarikciId,
    Map<String, int>? bedenDetaylari,
  }) async {
    try {
      final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
      final mevcutBedenDetayi = _parseBedenDetayi(sevk['beden_detaylari']);
      final sevkBedenDetayi = bedenDetaylari != null && bedenDetaylari.isNotEmpty
          ? _siraliBedenMap(Map<String, int>.from(bedenDetaylari)
            ..removeWhere((_, value) => value <= 0))
          : _oransalBedenDagitimi(mevcutBedenDetayi, adet);
      final hedefAsamaInfo = hedefAsamalar.firstWhere(
        (a) => a['key'] == hedefAsama,
        orElse: () => {'name': hedefAsama},
      );
      final currentUser = supabase.auth.currentUser;
      final firmaId = TenantManager.instance.requireFirmaId;

      final izinliKodlar =
          _izinliHedefAsamalar(sevk).map((a) => a['key'] as String).toSet();
      if (izinliKodlar.isNotEmpty && !izinliKodlar.contains(hedefAsama)) {
        throw Exception('Seçilen hedef aşama süreç sırası ile uyumlu değil.');
      }

      // 1. Kaynak tabloyu belirle ve güncelle
      // Önce onceki_asama'ya bak, sonra kaynak_tablo'ya, en son default olarak sevkiyat_kayitlari
      final oncekiAsama = sevk['onceki_asama']?.toString().toLowerCase();
      String kaynakTablo;

      if (sevk['kaynak_tablo'] != null) {
        kaynakTablo = sevk['kaynak_tablo'];
      } else if (sevk['alinan_adet'] != null) {
        kaynakTablo = DbTables.sevkiyatKayitlari;
      } else if (oncekiAsama != null) {
        // Önceki aşamaya göre kaynak tabloyu belirle
        kaynakTablo = _getTabloAdi(oncekiAsama) ?? DbTables.sevkiyatKayitlari;
      } else {
        kaynakTablo = DbTables.sevkiyatKayitlari;
      }

      final kaynakAsamaKodu =
          _kaynakAsamaKodu(sevk) ?? (oncekiAsama ?? 'sevkiyat');
      final sevkIslemKey =
          'sevk:${kaynakTablo}:${sevk['id']}:$hedefAsama:$adet';

      final irsaliye = await _sevkIrsaliyeService.olusturVeOnayla(
        firmaId: firmaId,
        kaynakAsama: kaynakAsamaKodu,
        hedefAsama: hedefAsama,
        kaynakTablo: kaynakTablo,
        kaynakKayitId: sevk['id'],
        modelId: sevk['model_id'],
        sevkAdedi: adet,
        hedefTedarikciId: tedarikciId,
        notlar: notlar,
        olusturanId: currentUser?.id,
        idempotencyKey: 'irsaliye:$sevkIslemKey',
      );
      final irsaliyeNo = (irsaliye['irsaliye_no'] ?? '').toString();

      debugPrint(
          '📦 Sevk işlemi - Kaynak tablo: $kaynakTablo, Önceki aşama: $oncekiAsama');

      final mevcutNot = (sevk['notlar'] ?? '').toString().trim();
        final sevkNotuTemel = notlar != null && notlar.isNotEmpty
          ? '[SEVK] $hedefAsama aşamasına $adet adet gönderildi. $notlar'
          : '[SEVK] $hedefAsama aşamasına $adet adet gönderildi.';
        final sevkNotu = irsaliyeNo.isNotEmpty
          ? '$sevkNotuTemel (Irsaliye: $irsaliyeNo)'
          : sevkNotuTemel;
      final birlesikNot = mevcutNot.isEmpty ? sevkNotu : '$mevcutNot\n$sevkNotu';

      if (kaynakTablo == DbTables.sevkiyatKayitlari) {
        // sevkiyat_kayitlari tablosunu güncelle
        final mevcutSevkEdilen = sevk['sevk_edilen_adet'] ?? 0;
        final alinanAdet = sevk['alinan_adet'] ?? 0;
        final yeniSevkEdilen = mevcutSevkEdilen + adet;
        final kalanAdet = alinanAdet - yeniSevkEdilen;
        final mevcutDurumNorm =
            WorkflowStateMachine.normalize(sevk['durum']?.toString());
        final ilkSevkHareketi =
            mevcutDurumNorm == 'beklemede' || mevcutDurumNorm == 'atandi';
        final yeniDurum = ilkSevkHareketi
            ? 'sevk_ediliyor'
            : (kalanAdet <= 0 ? 'tamamlandi' : 'sevk_ediliyor');
        final kalanBedenDetayi = _kalanBedenDagilimi(
          mevcutBedenDetayi,
          sevkBedenDetayi,
        );

        await _workflowTransitionService.applyTransition(
          tableName: DbTables.sevkiyatKayitlari,
          recordId: sevk['id'],
          firmaId: firmaId,
          fromStatus: sevk['durum']?.toString(),
          toStatus: yeniDurum,
          idempotencyKey: 'sevk:${sevk['id']}:$hedefAsama:$adet:$yeniDurum',
          extraFields: {
            'sevk_edilen_adet': yeniSevkEdilen,
            'kalan_adet': kalanAdet < 0 ? 0 : kalanAdet,
            'hedef_asama': hedefAsama,
            if (tedarikciId != null) 'hedef_tedarikci_id': tedarikciId,
            'sevkiyat_personeli_id': currentUser?.id,
            'sevk_tarihi': DateTime.now().toIso8601String(),
            'tamamlanma_tarihi':
                yeniDurum == 'tamamlandi' ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
            'notlar': birlesikNot,
          },
        );

        if (mevcutBedenDetayi.isNotEmpty || sevkBedenDetayi.isNotEmpty) {
          await _opsiyonelBedenDetayiGuncelle(
            sevkiyatId: sevk['id'],
            firmaId: firmaId,
            bedenDetayi: kalanBedenDetayi,
          );
        }

        // 2. Sevkiyat detayı kaydet
        try {
          await _esnekSevkiyatDetayInsert({
            'sevkiyat_id': sevk['id'],
            'sevk_adet': adet,
            'hedef_asama': hedefAsama,
            'hedef_tedarikci_id': tedarikciId,
            'sevk_eden_id': currentUser?.id,
            'sevk_tarihi': DateTime.now().toIso8601String(),
            'irsaliye_id': irsaliye['id'],
            'irsaliye_no': irsaliyeNo,
            'notlar': notlar,
            if (sevkBedenDetayi.isNotEmpty)
              'beden_detaylari': sevkBedenDetayi,
            'firma_id': firmaId,
          });
          debugPrint('✅ Sevkiyat detayı kaydedildi');
        } catch (e) {
          debugPrint('⚠️ Sevkiyat detayı kaydedilemedi: $e');
        }

        debugPrint('✅ sevkiyat_kayitlari güncellendi - Yeni durum: $yeniDurum');
      } else {
        // Kaynak tabloyu güncelle (yikama_atamalari, paketleme_atamalari vb.)
        debugPrint('📦 Kaynak tablo güncelleniyor: $kaynakTablo');
        await _workflowTransitionService.applyTransition(
          tableName: kaynakTablo,
          recordId: sevk['id'],
          firmaId: firmaId,
          fromStatus: sevk['durum']?.toString(),
          toStatus: 'sevk_ediliyor',
          idempotencyKey: 'sevk:${kaynakTablo}:${sevk['id']}:$hedefAsama:$adet',
          extraFields: {
            'hedef_asama': hedefAsama,
            'updated_at': DateTime.now().toIso8601String(),
            'notlar': birlesikNot,
          },
        );
        debugPrint('✅ $kaynakTablo güncellendi');
      }

      // 3. Hedef aşamaya atama yap
      final hedefTabloAdi = _getTabloAdi(hedefAsama);
      if (hedefTabloAdi != null) {
        final hedefAtamaKey = 'sevk:${sevk['id']}:$hedefAsama';
        final hedefEtiket = '[IDEMP:$hedefAtamaKey]';

        // Atama verisi hazırla
        final atamaData = {
          'model_id': sevk['model_id'],
          'firma_id': firmaId,
          'adet': adet,
          'talep_edilen_adet': adet,
          'tamamlanan_adet': 0,
          'durum':
              'bekleyen', // ÖNEMLİ: Önce bekleyen durumunda gelsin, sonra onaylansın
          'atama_tarihi': DateTime.now().toIso8601String(),
          'notlar':
              'Sevkiyattan geldi - ${model['marka']} ${model['item_no']} - $adet adet $hedefEtiket',
          'idempotency_key': hedefAtamaKey,
          if (sevkBedenDetayi.isNotEmpty) 'beden_detaylari': sevkBedenDetayi,
        };

        // Tedarikci ID varsa ekle (yıkama, nakış gibi dış atölyeler için)
        if (tedarikciId != null) {
          atamaData['tedarikci_id'] = tedarikciId;
        }

        Map<String, dynamic>? mevcutAtama;
        try {
          mevcutAtama = await supabase
              .from(hedefTabloAdi)
              .select('id, adet, talep_edilen_adet, notlar')
              .eq('firma_id', firmaId)
              .eq('idempotency_key', hedefAtamaKey)
              .maybeSingle();
        } catch (_) {
          // idempotency_key kolonu eski şemada olmayabilir.
        }

        if (mevcutAtama == null) {
          final adaylar = await supabase
              .from(hedefTabloAdi)
              .select('id, adet, talep_edilen_adet, notlar')
              .eq('firma_id', firmaId)
              .eq('model_id', sevk['model_id'])
              .order('created_at', ascending: false)
              .limit(10);

          for (final aday in List<Map<String, dynamic>>.from(adaylar)) {
            if ((aday['notlar'] ?? '').toString().contains(hedefEtiket)) {
              mevcutAtama = aday;
              break;
            }
          }
        }

        if (mevcutAtama != null) {
          final mevcutAdet = (mevcutAtama['adet'] as int?) ??
              (mevcutAtama['talep_edilen_adet'] as int?) ??
              0;
          final yeniAdet = mevcutAdet + adet;
          await supabase
              .from(hedefTabloAdi)
              .update({
                'adet': yeniAdet,
                'talep_edilen_adet': yeniAdet,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', mevcutAtama['id'])
              .eq('firma_id', firmaId);
          debugPrint('✅ $hedefTabloAdi mevcut atama güncellendi (idempotent).');
        } else {
          try {
            await supabase.from(hedefTabloAdi).insert(atamaData);
          } catch (_) {
            final fallback = Map<String, dynamic>.from(atamaData)
              ..remove('idempotency_key')
              ..remove('beden_detaylari');
            await supabase.from(hedefTabloAdi).insert(fallback);
          }
          debugPrint(
              '✅ $hedefTabloAdi tablosuna yeni atama oluşturuldu (tedarikci_id: $tedarikciId)');
        }

        // 4. Hedef aşama personeline bildirim gönder
        try {
          await BildirimService().roleGoreBildirimGonder(
            rol: hedefAsama,
            baslik: '📦 Yeni Sevkiyat Geldi',
            mesaj:
                '${model['marka']} ${model['item_no']} - $adet adet sevkiyattan geldi. İşleme alınmayı bekliyor.',
            tip: 'sevkiyat_geldi',
            modelId: sevk['model_id']?.toString(),
            asama: 'Sevkiyat',
          );
          debugPrint('✅ $hedefAsama rolüne bildirim gönderildi');
        } catch (e) {
          debugPrint('⚠️ Bildirim gönderilemedi: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(irsaliyeNo.isNotEmpty
                ? '✅ $adet adet ${hedefAsamaInfo['name']} aşamasına sevk edildi (İrsaliye: $irsaliyeNo)'
                : '✅ $adet adet ${hedefAsamaInfo['name']} aşamasına sevk edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _verileriYukle();
    } catch (e) {
      debugPrint('❌ Sevk hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  String? _getTabloAdi(String asama) {
    switch (asama) {
      case 'nakis':
        return DbTables.nakisAtamalari;
      case 'konfeksiyon':
        return DbTables.konfeksiyonAtamalari;
      case 'yikama':
        return DbTables.yikamaAtamalari;
      case 'utu':
        return DbTables.utuAtamalari;
      case 'ilik_dugme':
        return DbTables.ilikDugmeAtamalari;
      case 'paketleme':
        return DbTables.paketlemeAtamalari;
      default:
        return null;
    }
  }

  Future<void> _sevkTamamla(Map<String, dynamic> sevk) async {
    try {
      final kaynakTablo = (sevk['kaynak_tablo']?.toString() ??
              (sevk['alinan_adet'] != null
                  ? DbTables.sevkiyatKayitlari
                  : DbTables.paketlemeAtamalari))
          .toString();

        final hedefTablo = sevk['alinan_adet'] != null
          ? DbTables.sevkiyatKayitlari
          : kaynakTablo;

      await _workflowTransitionService.applyTransition(
        tableName: hedefTablo,
        recordId: sevk['id'],
        firmaId: TenantManager.instance.requireFirmaId,
        fromStatus: sevk['durum']?.toString(),
        toStatus: 'tamamlandi',
        idempotencyKey: 'sevk:${sevk['id']}:tamamla',
        extraFields: {
          'tamamlanma_tarihi': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          if (hedefTablo == DbTables.sevkiyatKayitlari &&
              sevk['alinan_adet'] != null)
            'sevk_edilen_adet': sevk['alinan_adet'],
          if (hedefTablo == DbTables.sevkiyatKayitlari) 'kalan_adet': 0,
        },
      );

      if (mounted) {
        context.showSuccessSnackBar('✅ Sevkiyat tamamlandı');
      }

      await _verileriYukle();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  void _showDetayDialog(Map<String, dynamic> sevk) {
    final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final modelId = sevk['model_id'] ?? model['id'];
    final bedenDetayi = _parseBedenDetayi(sevk['beden_detaylari']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${model['marka']} - ${model['item_no']}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetaySatiri('Marka', model['marka']),
                _buildDetaySatiri('Model No', model['item_no']),
                _buildDetaySatiri('Renk', model['renk']),
                _buildDetaySatiri('Adet', '${sevk['adet'] ?? model['adet']}'),
                if (bedenDetayi.isNotEmpty)
                  _buildDetaySatiri(
                    'Beden Dağılımı',
                    _bedenDagilimiMetni(bedenDetayi),
                  ),
                _buildDetaySatiri('Durum', sevk['durum']),
                if (sevk['hedef_asama'] != null)
                  _buildDetaySatiri('Hedef Aşama', sevk['hedef_asama']),
                if (model['termin_tarihi'] != null)
                  _buildDetaySatiri(
                      'Termin',
                      DateFormat('dd.MM.yyyy')
                          .format(DateTime.parse(model['termin_tarihi']))),
                if (sevk['atama_tarihi'] != null)
                  _buildDetaySatiri(
                      'Atama Tarihi',
                      DateFormat('dd.MM.yyyy HH:mm')
                          .format(DateTime.parse(sevk['atama_tarihi']))),
                _buildDetaySatiri('Notlar', _temizSevkNotu(sevk['notlar'])),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetaySatiri(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }
}
