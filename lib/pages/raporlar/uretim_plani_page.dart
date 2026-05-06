import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class UretimPlaniPage extends StatefulWidget {
  const UretimPlaniPage({super.key});

  @override
  State<UretimPlaniPage> createState() => _UretimPlaniPageState();
}

class _UretimPlaniPageState extends State<UretimPlaniPage> {
  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _tableVerticalScrollController = ScrollController();
  final ScrollController _tableHorizontalScrollController = ScrollController();

  final List<Map<String, String>> _asamalar = const [
    {'kod': 'dokuma', 'ad': 'Dokuma', 'tablo': DbTables.dokumaAtamalari},
    {'kod': 'nakis', 'ad': 'Nakış', 'tablo': DbTables.nakisAtamalari},
    {
      'kod': 'konfeksiyon',
      'ad': 'Konfeksiyon',
      'tablo': DbTables.konfeksiyonAtamalari,
    },
    {'kod': 'yikama', 'ad': 'Yıkama', 'tablo': DbTables.yikamaAtamalari},
    {'kod': 'utu', 'ad': 'Ütü', 'tablo': DbTables.utuAtamalari},
    {
      'kod': 'ilik_dugme',
      'ad': 'İlik Düğme',
      'tablo': DbTables.ilikDugmeAtamalari,
    },
    {
      'kod': 'paketleme',
      'ad': 'Paketleme',
      'tablo': DbTables.paketlemeAtamalari,
    },
  ];

  bool _yukleniyor = false;
  String _arama = '';
  List<Map<String, dynamic>> _kayitlar = [];
  List<Map<String, dynamic>> _modeller = [];
  List<Map<String, dynamic>> _tedarikciler = [];
  Map<String, double> _tedarikciModelKapasiteMap = {};
  static const List<String> _durumSecenekleri = [
    'planlandi',
    'atandi',
    'bekleyen',
    'onaylandi',
    'baslandi',
    'baslatildi',
    'uretimde',
    'kismi_tamamlandi',
    'tamamlandi',
    'reddedildi',
    'iptal',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _tableVerticalScrollController.dispose();
    _tableHorizontalScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtreliKayitlar {
    if (_arama.trim().isEmpty) return _kayitlar;

    final q = _arama.toLowerCase().trim();
    return _kayitlar.where((k) {
      final model = (k['model_kodu'] ?? '').toString().toLowerCase();
      final marka = (k['model_marka'] ?? '').toString().toLowerCase();
      final renk = (k['model_renk'] ?? '').toString().toLowerCase();
      final karisim = (k['model_karisim'] ?? '').toString().toLowerCase();
      final iplikTed = (k['iplik_tedarikcisi'] ?? '').toString().toLowerCase();
      final asama = (k['asama_adi'] ?? '').toString().toLowerCase();
      final tedarikci = (k['tedarikci_adi'] ?? '').toString().toLowerCase();
      final diger = (k['diger_asamalar'] ?? '').toString().toLowerCase();
      final durum = (k['durum'] ?? '').toString().toLowerCase();
      return model.contains(q) ||
          marka.contains(q) ||
          renk.contains(q) ||
          karisim.contains(q) ||
          iplikTed.contains(q) ||
          asama.contains(q) ||
          tedarikci.contains(q) ||
          diger.contains(q) ||
          durum.contains(q);
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() => _yukleniyor = true);
    try {
      final modelsResp = await _supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', _firmaId)
          .order('item_no');
      _modeller = List<Map<String, dynamic>>.from(modelsResp);

      _tedarikciler = await _fetchTedarikciler();
      final modelKapasiteleri = await _fetchTedarikciModelKapasiteleri();
      _tedarikciModelKapasiteMap = {
        for (final k in modelKapasiteleri)
          if (_kapasiteKey(k['tedarikci_id'], k['model_id']) != null)
            _kapasiteKey(k['tedarikci_id'], k['model_id'])!:
                _parseDouble(k['gunluk_kapasite']) ?? 0,
      };

      final modelIndex = <String, Map<String, dynamic>>{};
      for (final m in _modeller) {
        final modelId = m['id']?.toString();
        if (modelId != null && modelId.isNotEmpty) {
          modelIndex[modelId] = m;
        }
      }

      final tedarikciIndex = <String, String>{};
      for (final t in _tedarikciler) {
        final id = t['id']?.toString();
        if (id == null || id.isEmpty) continue;
        tedarikciIndex[id] = _tedarikciEtiket(t);
      }

      final satirlar = <Map<String, dynamic>>[];
      for (final asama in _asamalar) {
        final asamaKodu = asama['kod']!;
        final asamaAdi = asama['ad']!;
        final tablo = asama['tablo']!;

        try {
          final response = await _supabase
              .from(tablo)
              .select(
                  'id, model_id, tedarikci_id, uretim_baslangic_tarihi, planlanan_bitis_tarihi, durum, created_at')
              .eq('firma_id', _firmaId)
              .order('created_at', ascending: false);

          for (final raw in List<Map<String, dynamic>>.from(response)) {
            final modelId = raw['model_id']?.toString();
            if (modelId == null || modelId.isEmpty) continue;

            final model = modelIndex[modelId];
            final tedarikciId = raw['tedarikci_id'];

            satirlar.add({
              ...raw,
              'asama_kodu': asamaKodu,
              'asama_adi': asamaAdi,
              'asama_tablo': tablo,
              'model_kodu':
                  (model?['item_no'] ?? model?['model_adi'] ?? '-').toString(),
              'model_marka': (model?['marka'] ?? '-').toString(),
              'model_adet':
                  ((model?['toplam_adet'] ?? model?['adet'] ?? 0) as num?)
                          ?.toInt() ??
                      0,
              'tedarikci_adi':
                  tedarikciIndex[tedarikciId?.toString() ?? ''] ?? '-',
              'tedarikci_gunluk_kapasite': _getPlanKapasitesi(
                tedarikciId: tedarikciId,
                modelId: modelId,
              ),
            });
          }
        } catch (e) {
          AppLogger.debug('$tablo plan kayitlari okunamadi: $e');
        }
      }

      final latest = <String, Map<String, dynamic>>{};
      for (final satir in satirlar) {
        final key =
            '${satir['model_id']?.toString() ?? ''}-${satir['asama_kodu']?.toString() ?? ''}';
        final mevcut = latest[key];
        if (mevcut == null) {
          latest[key] = satir;
          continue;
        }

        final mevcutTarih = _parseDate(mevcut['created_at']);
        final yeniTarih = _parseDate(satir['created_at']);
        if (yeniTarih != null &&
            (mevcutTarih == null || yeniTarih.isAfter(mevcutTarih))) {
          latest[key] = satir;
        }
      }

      final modelAsamaOzet = <String, Map<String, dynamic>>{};
      for (final satir in latest.values) {
        final modelId = satir['model_id']?.toString();
        final asamaKodu = satir['asama_kodu']?.toString();
        if (modelId == null || modelId.isEmpty || asamaKodu == null) continue;
        final ozet = modelAsamaOzet.putIfAbsent(modelId, () => {});
        ozet['${asamaKodu}_durum'] = (satir['durum'] ?? '-').toString();
        ozet['${asamaKodu}_tedarikci'] = (satir['tedarikci_adi'] ?? '-').toString();
      }

      final kayitlar = latest.values.map((satir) {
        final modelId = satir['model_id']?.toString() ?? '';
        final model = modelIndex[modelId];
        final ozet = modelAsamaOzet[modelId] ?? const <String, dynamic>{};
        final asamaKodu = satir['asama_kodu']?.toString();
        return {
          ...satir,
          'model_renk': _modelRenk(model),
          'model_karisim':
              (model?['iplik_karisimi'] ?? model?['karisim'] ?? '-').toString(),
          'termin_tarihi': model?['termin_tarihi'] ?? model?['termin'],
          'kase_durumu': _kaseDurumuMetni(model),
          'iplik_tedarikcisi':
              (model?['iplik_tedarikci'] ?? model?['iplik_tedarikcisi'] ?? '-')
                  .toString(),
          'dokuma_durum': (ozet['dokuma_durum'] ?? '-').toString(),
          'dokuma_tedarikci': (ozet['dokuma_tedarikci'] ?? '-').toString(),
          'diger_asamalar': _digerAsamalarMetni(ozet, aktifAsamaKodu: asamaKodu),
          'final_tarihi': _cozFinalTarihi(model),
        };
      }).toList()
        ..sort((a, b) {
          final modelCmp = (a['model_kodu'] ?? '')
              .toString()
              .compareTo((b['model_kodu'] ?? '').toString());
          if (modelCmp != 0) return modelCmp;

          final aSira = _asamaSira(a['asama_kodu']?.toString() ?? '');
          final bSira = _asamaSira(b['asama_kodu']?.toString() ?? '');
          if (aSira != bSira) return aSira.compareTo(bSira);

          final aBaslangic = _parseDate(a['uretim_baslangic_tarihi']);
          final bBaslangic = _parseDate(b['uretim_baslangic_tarihi']);
          if (aBaslangic == null && bBaslangic == null) return 0;
          if (aBaslangic == null) return 1;
          if (bBaslangic == null) return -1;
          return aBaslangic.compareTo(bBaslangic);
        });

      if (!mounted) return;
      setState(() {
        _kayitlar = kayitlar;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      context.showErrorSnackBar('Üretim planı yüklenemedi: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTedarikciler() async {
    final denemeler = [
      ('id, firma_adi, sirket, ad, gunluk_uretim_kapasitesi', 'firma_adi'),
      ('id, firma_adi, sirket, ad', 'firma_adi'),
      ('id, ad, sirket, gunluk_uretim_kapasitesi', 'ad'),
      ('id, ad, sirket', 'ad'),
    ];

    dynamic lastError;
    for (final deneme in denemeler) {
      try {
        final tedResp = await _supabase
            .from(DbTables.tedarikciler)
            .select(deneme.$1)
            .eq('firma_id', _firmaId)
            .order(deneme.$2);
        return List<Map<String, dynamic>>.from(tedResp);
      } on PostgrestException catch (e) {
        lastError = e;
        if (e.code == '42703') {
          continue;
        }
        rethrow;
      }
    }

    throw lastError ?? 'Tedarikçiler alınamadı';
  }

  Future<List<Map<String, dynamic>>> _fetchTedarikciModelKapasiteleri() async {
    try {
      final response = await _supabase
          .from(DbTables.tedarikciModelKapasiteleri)
          .select('tedarikci_id, model_id, gunluk_kapasite')
          .eq('firma_id', _firmaId);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      if (_isMissingRelationError(e, DbTables.tedarikciModelKapasiteleri)) {
        return [];
      }
      rethrow;
    }
  }

  String? _kapasiteKey(dynamic tedarikciId, dynamic modelId) {
    final tid = tedarikciId?.toString().trim();
    final mid = modelId?.toString().trim();
    if (tid == null || tid.isEmpty || mid == null || mid.isEmpty) return null;
    return '$tid|$mid';
  }

  double? _getPlanKapasitesi({
    required dynamic tedarikciId,
    required dynamic modelId,
  }) {
    final key = _kapasiteKey(tedarikciId, modelId);
    if (key != null && _tedarikciModelKapasiteMap.containsKey(key)) {
      return _tedarikciModelKapasiteMap[key];
    }

    final tedarikci = _tedarikciler.firstWhere(
      (t) => t['id']?.toString() == tedarikciId?.toString(),
      orElse: () => <String, dynamic>{},
    );
    return _parseDouble(tedarikci['gunluk_uretim_kapasitesi']);
  }

  String _modelRenk(Map<String, dynamic>? model) {
    return (model?['renk'] ?? model?['renk_kombinasyonu'] ?? '-').toString();
  }

  String _kaseDurumuMetni(Map<String, dynamic>? model) {
    final value = model?['kase_onayi'] ?? model?['kase_onay_durumu'];
    if (value == true) return 'Onayli';
    if (value == false) return 'Onaysiz';
    final metin = value?.toString().trim();
    if (metin == null || metin.isEmpty) return '-';
    return metin;
  }

  dynamic _cozFinalTarihi(Map<String, dynamic>? model) {
    return model?['final_tarihi'] ?? model?['final_tarih'] ?? model?['teslim_tarihi'];
  }

  String _digerAsamalarMetni(Map<String, dynamic> ozet, {String? aktifAsamaKodu}) {
    final parcalar = <String>[];
    for (final asama in _asamalar) {
      final kod = asama['kod'] ?? '';
      if (kod.isEmpty || kod == 'dokuma' || kod == aktifAsamaKodu) continue;
      final durum = (ozet['${kod}_durum'] ?? '-').toString();
      parcalar.add('${asama['ad']}: $durum');
    }
    if (parcalar.isEmpty) return '-';
    return parcalar.join(' | ');
  }

  int _asamaSira(String asamaKodu) {
    final idx = _asamalar.indexWhere((a) => a['kod'] == asamaKodu);
    return idx >= 0 ? idx : 999;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString().trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  String _formatDecimal(num value) {
    if ((value - value.round()).abs() < 0.01) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  int _planGunSayisi(DateTime baslangic, DateTime bitis) {
    final b = DateTime(baslangic.year, baslangic.month, baslangic.day);
    final s = DateTime(bitis.year, bitis.month, bitis.day);
    return s.difference(b).inDays + 1;
  }

  List<DateTime> _dateRangeDays(DateTime baslangic, DateTime bitis) {
    final b = DateTime(baslangic.year, baslangic.month, baslangic.day);
    final s = DateTime(bitis.year, bitis.month, bitis.day);
    if (s.isBefore(b)) return const [];

    final gunler = <DateTime>[];
    var current = b;
    while (!current.isAfter(s)) {
      gunler.add(current);
      current = current.add(const Duration(days: 1));
    }
    return gunler;
  }

  bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  int _calismaGunSayisi(
    DateTime baslangic,
    DateTime bitis,
    List<DateTime> seciliCalismaGunleri,
  ) {
    if (seciliCalismaGunleri.isEmpty) {
      return _planGunSayisi(baslangic, bitis);
    }

    final b = DateTime(baslangic.year, baslangic.month, baslangic.day);
    final s = DateTime(bitis.year, bitis.month, bitis.day);
    final set = seciliCalismaGunleri
        .map((d) => DateTime(d.year, d.month, d.day))
        .where((d) => !d.isBefore(b) && !d.isAfter(s))
        .toSet();
    return set.length;
  }

  double _gerekenGunlukAdet(int toplamAdet, DateTime baslangic, DateTime bitis) {
    final gun = _planGunSayisi(baslangic, bitis);
    if (gun <= 0) return 0;
    return toplamAdet / gun;
  }

  double _gerekenGunlukAdetByGunSayisi(int toplamAdet, int gunSayisi) {
    if (gunSayisi <= 0) return 0;
    return toplamAdet / gunSayisi;
  }

  bool _isMissingColumnError(PostgrestException e, String column) {
    if (e.code != '42703') return false;
    final mesaj = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
    return mesaj.contains(column.toLowerCase());
  }

  bool _isMissingRelationError(PostgrestException e, String relation) {
    if (e.code != '42P01' && e.code != 'PGRST205') return false;
    final mesaj = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
    final relationLower = relation.toLowerCase();
    return mesaj.contains(relationLower) ||
        mesaj.contains('public.$relationLower') ||
        mesaj.contains('could not find the table');
  }

  bool _isDurumConstraintError(PostgrestException e) {
    if (e.code != '23514') return false;
    final mesaj = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
    return mesaj.contains('durum_check') || mesaj.contains('_durum_check');
  }

  String _normalizeDurumForDb(String durum) {
    final d = durum.trim().toLowerCase();
    switch (d) {
      case 'planlandi':
        return 'atandi';
      case 'isleniyor':
        return 'uretimde';
      default:
        return d;
    }
  }

  List<String> _durumAdaylari(String seciliDurum) {
    final adaylar = <String>[
      _normalizeDurumForDb(seciliDurum),
      'atandi',
      'onaylandi',
      'baslandi',
      'baslatildi',
      'uretimde',
      'kismi_tamamlandi',
      'tamamlandi',
      'bekleyen',
      'iptal',
    ];
    final unique = <String>[];
    for (final a in adaylar) {
      if (!unique.contains(a)) unique.add(a);
    }
    return unique;
  }

  Future<List<DateTime>?> _showCalismaGunSecimDialog({
    required BuildContext context,
    required DateTime baslangic,
    required DateTime bitis,
    required List<DateTime> initialSelected,
  }) async {
    final gunler = _dateRangeDays(baslangic, bitis);
    final initialSet = initialSelected
        .map((d) => DateTime(d.year, d.month, d.day).toIso8601String())
        .toSet();
    final varsayilanSet = gunler
        .where((d) => !_isWeekend(d))
        .map((d) => d.toIso8601String())
        .toSet();
    final secili = initialSet.isEmpty ? varsayilanSet : initialSet;

    final sonuc = await showDialog<List<DateTime>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Çalışma Günlerini Seç'),
          content: SizedBox(
            width: 440,
            height: 420,
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setStateDialog(() {
                        secili
                          ..clear()
                          ..addAll(gunler
                              .where((d) => !_isWeekend(d))
                              .map((d) => d.toIso8601String()));
                      }),
                      child: const Text('Hafta İçi'),
                    ),
                    TextButton(
                      onPressed: () => setStateDialog(() {
                        secili
                          ..clear()
                          ..addAll(gunler.map((d) => d.toIso8601String()));
                      }),
                      child: const Text('Tümü'),
                    ),
                    TextButton(
                      onPressed: () => setStateDialog(() => secili.clear()),
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: gunler.length,
                    itemBuilder: (_, i) {
                      final d = gunler[i];
                      final key = d.toIso8601String();
                      final isSecili = secili.contains(key);
                      return CheckboxListTile(
                        value: isSecili,
                        dense: true,
                        title: Text(DateFormat('dd.MM.yyyy').format(d)),
                        subtitle:
                            Text(_isWeekend(d) ? 'Hafta Sonu' : 'Çalışma Günü'),
                        onChanged: (v) => setStateDialog(() {
                          if (v == true) {
                            secili.add(key);
                          } else {
                            secili.remove(key);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final list = secili
                    .map((s) => DateTime.parse(s))
                    .toList()
                  ..sort();
                Navigator.pop(dialogContext, list);
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );

    return sonuc;
  }

  String _formatDate(dynamic value) {
    final dt = _parseDate(value);
    if (dt == null) return '-';
    return DateFormat('dd.MM.yyyy').format(dt.toLocal());
  }

  Color _durumColor(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return const Color(0xFF15803D);
      case 'uretimde':
      case 'isleniyor':
        return const Color(0xFF2563EB);
      case 'atandi':
      case 'onaylandi':
      case 'planlandi':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _tedarikciEtiket(Map<String, dynamic> t) {
    final firmaAdi = (t['firma_adi'] ?? '').toString().trim();
    final sirket = (t['sirket'] ?? '').toString().trim();
    final ad = (t['ad'] ?? '').toString().trim();
    if (firmaAdi.isNotEmpty) return firmaAdi;
    if (sirket.isNotEmpty) return sirket;
    if (ad.isNotEmpty) return ad;
    return '-';
  }

  dynamic _normalizeTedarikciId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s) ?? s;
  }

  Future<void> _kaydetTedarikciModelKapasitesi({
    required dynamic tedarikciId,
    required String modelId,
    required double gunlukKapasite,
  }) async {
    final normalizedId = _normalizeTedarikciId(tedarikciId);
    final key = _kapasiteKey(normalizedId, modelId);
    if (normalizedId == null || key == null) return;

    try {
      await _supabase.from(DbTables.tedarikciModelKapasiteleri).upsert(
        {
          'firma_id': _firmaId,
          'tedarikci_id': normalizedId.toString(),
          'model_id': modelId,
          'gunluk_kapasite': gunlukKapasite,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'firma_id,tedarikci_id,model_id',
      );
      _tedarikciModelKapasiteMap[key] = gunlukKapasite;
      return;
    } on PostgrestException catch (e) {
      if (!_isMissingRelationError(e, DbTables.tedarikciModelKapasiteleri) &&
          !_isMissingColumnError(e, 'gunluk_kapasite')) {
        rethrow;
      }
    }

    // Fallback: eslesme tablosu yoksa onceki supplier-genel kolonunu guncelle.
    try {
      await _supabase
          .from(DbTables.tedarikciler)
          .update({'gunluk_uretim_kapasitesi': gunlukKapasite})
          .eq('firma_id', _firmaId)
          .eq('id', normalizedId);
    } on PostgrestException catch (e) {
      if (!_isMissingColumnError(e, 'gunluk_uretim_kapasitesi')) {
        rethrow;
      }
    }

    final idx = _tedarikciler
        .indexWhere((t) => t['id']?.toString() == normalizedId.toString());
    if (idx >= 0) {
      _tedarikciler[idx]['gunluk_uretim_kapasitesi'] = gunlukKapasite;
    }
  }

  Future<void> _kaydetModelFinalTarihi({
    required String modelId,
    required DateTime finalTarih,
  }) async {
    final alanlar = ['final_tarihi', 'final_tarih', 'teslim_tarihi'];
    final tarihDegeri = finalTarih.toIso8601String();

    for (final alan in alanlar) {
      try {
        await _supabase
            .from(DbTables.trikoTakip)
            .update({alan: tarihDegeri})
            .eq('firma_id', _firmaId)
            .eq('id', modelId);
        return;
      } on PostgrestException catch (e) {
        if (_isMissingColumnError(e, alan)) {
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _showPlanDialog({
    Map<String, dynamic>? kayit,
    String? modelId,
    String? asamaKodu,
    bool lockModel = false,
    bool lockAsama = false,
  }) async {
    String? seciliModelId = kayit?['model_id']?.toString() ?? modelId;
    String? seciliAsamaKodu = kayit?['asama_kodu']?.toString() ?? asamaKodu;
    dynamic seciliTedarikciId = kayit?['tedarikci_id'];
    String seciliDurum = (kayit?['durum'] ?? 'planlandi').toString();

    DateTime? baslangic = _parseDate(kayit?['uretim_baslangic_tarihi']);
    DateTime? bitis = _parseDate(kayit?['planlanan_bitis_tarihi']);
    DateTime? finalTarih = _parseDate(kayit?['final_tarihi']);
    List<DateTime> seciliCalismaGunleri = [];

    void varsayilanCalismaGunleriniKur() {
      if (baslangic == null || bitis == null || bitis!.isBefore(baslangic!)) {
        seciliCalismaGunleri = [];
        return;
      }
      seciliCalismaGunleri =
          _dateRangeDays(baslangic!, bitis!).where((d) => !_isWeekend(d)).toList();
    }

    varsayilanCalismaGunleriniKur();

    final mevcutKapasite =
        _parseDouble(kayit?['tedarikci_gunluk_kapasite']) ??
            _getPlanKapasitesi(
              tedarikciId: seciliTedarikciId,
              modelId: seciliModelId,
            );
    final kapasiteController = TextEditingController(
      text: mevcutKapasite == null ? '' : _formatDecimal(mevcutKapasite),
    );

    final modelOps = _modeller
        .where((m) => (m['id']?.toString().isNotEmpty ?? false))
        .toList();

    if (!_durumSecenekleri.contains(seciliDurum)) {
      seciliDurum = 'planlandi';
    }

    if (modelOps.isEmpty) {
      context.showErrorSnackBar('Plan oluşturmak için model bulunamadı');
      return;
    }

    if (_tedarikciler.isEmpty) {
      context.showErrorSnackBar('Plan oluşturmak için tedarikçi bulunamadı');
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title:
              Text(kayit == null ? 'Yeni Üretim Planı' : 'Üretim Planı Düzenle'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: seciliModelId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Model *',
                      border: OutlineInputBorder(),
                    ),
                    items: modelOps.map((m) {
                      final id = m['id']?.toString() ?? '';
                      final marka = (m['marka'] ?? '-').toString();
                      final kod =
                          (m['item_no'] ?? m['model_adi'] ?? '-').toString();
                      return DropdownMenuItem(
                        value: id,
                        child: Text('$marka - $kod',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: lockModel
                        ? null
                        : (v) => setStateDialog(() {
                              seciliModelId = v;
                              final kapasite = _getPlanKapasitesi(
                                tedarikciId: seciliTedarikciId,
                                modelId: seciliModelId,
                              );
                              if (kapasite != null) {
                                kapasiteController.text = _formatDecimal(kapasite);
                              }
                            }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: seciliAsamaKodu,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Üretim Aşaması *',
                      border: OutlineInputBorder(),
                    ),
                    items: _asamalar
                        .map((a) => DropdownMenuItem(
                              value: a['kod'],
                              child: Text(a['ad'] ?? '-'),
                            ))
                        .toList(),
                    onChanged: lockAsama
                      ? null
                      : (v) => setStateDialog(() => seciliAsamaKodu = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<dynamic>(
                    initialValue: seciliTedarikciId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tedarikçi *',
                      border: OutlineInputBorder(),
                    ),
                    items: _tedarikciler
                        .map((t) => DropdownMenuItem<dynamic>(
                              value: t['id'],
                              child: Text(_tedarikciEtiket(t),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setStateDialog(() {
                      seciliTedarikciId = v;
                      final kapasite = _getPlanKapasitesi(
                        tedarikciId: seciliTedarikciId,
                        modelId: seciliModelId,
                      );
                      if (kapasite != null) {
                        kapasiteController.text = _formatDecimal(kapasite);
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: baslangic ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              setStateDialog(() {
                                baslangic = d;
                                varsayilanCalismaGunleriniKur();
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Başlangıç *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatDate(baslangic)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: bitis ?? (baslangic ?? DateTime.now()),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              setStateDialog(() {
                                bitis = d;
                                varsayilanCalismaGunleriniKur();
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Bitiş *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatDate(bitis)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: (baslangic == null || bitis == null)
                        ? null
                        : () async {
                            final sonuc = await _showCalismaGunSecimDialog(
                              context: ctx,
                              baslangic: baslangic!,
                              bitis: bitis!,
                              initialSelected: seciliCalismaGunleri,
                            );
                            if (sonuc != null) {
                              setStateDialog(() => seciliCalismaGunleri = sonuc);
                            }
                          },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      seciliCalismaGunleri.isEmpty
                          ? 'Çalışma Günleri Seç'
                          : 'Çalışma Günleri: ${seciliCalismaGunleri.length}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (seciliAsamaKodu == 'utu' || seciliAsamaKodu == 'paketleme')
                    Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: finalTarih ?? (bitis ?? DateTime.now()),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              setStateDialog(() => finalTarih = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Final Tarihi *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatDate(finalTarih)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  TextFormField(
                    controller: kapasiteController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tedarikçi Günlük Üretim Kapasitesi *',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: 250',
                    ),
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (_) {
                    final seciliModel = _modeller.firstWhere(
                      (m) => m['id']?.toString() == seciliModelId,
                      orElse: () => <String, dynamic>{},
                    );
                    final toplamAdet =
                        ((seciliModel['toplam_adet'] ?? seciliModel['adet'] ?? 0)
                                    as num?)
                                ?.toInt() ??
                            0;
                    final kapasite = _parseDouble(kapasiteController.text);
                    final hasDates = baslangic != null &&
                        bitis != null &&
                        !bitis!.isBefore(baslangic!);

                    if (!hasDates) {
                      return const SizedBox.shrink();
                    }

                    final gunSayisi = _calismaGunSayisi(
                      baslangic!,
                      bitis!,
                      seciliCalismaGunleri,
                    );
                    final gereken =
                        _gerekenGunlukAdetByGunSayisi(toplamAdet, gunSayisi);
                    final yetersiz = kapasite != null && kapasite < gereken;
                    final renk =
                        yetersiz ? const Color(0xFFB91C1C) : const Color(0xFF166534);

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: renk.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toplam Adet: $toplamAdet'),
                          Text('Plan Süresi: $gunSayisi çalışma günü'),
                          Text(
                            'Gereken Günlük Üretim: ${_formatDecimal(gereken)} adet/gün',
                          ),
                          Text(
                            kapasite == null
                                ? 'Kapasite girilmedi'
                                : (yetersiz
                                    ? 'Kapasite yetersiz (${_formatDecimal(kapasite)} adet/gün)'
                                    : 'Kapasite yeterli (${_formatDecimal(kapasite)} adet/gün)'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: renk,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: seciliDurum,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: _durumSecenekleri
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => seciliDurum = v);
                      }
                    },
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
            ElevatedButton(
              onPressed: () async {
                if (seciliModelId == null ||
                    seciliAsamaKodu == null ||
                    seciliTedarikciId == null ||
                    baslangic == null ||
                    bitis == null) {
                  ctx.showErrorSnackBar('Lütfen zorunlu alanları doldurun');
                  return;
                }

                if (bitis!.isBefore(baslangic!)) {
                  ctx.showErrorSnackBar('Bitiş tarihi başlangıçtan önce olamaz');
                  return;
                }

                if ((seciliAsamaKodu == 'utu' || seciliAsamaKodu == 'paketleme') &&
                    finalTarih == null) {
                  ctx.showErrorSnackBar('Ütü/Paketleme sonrası final tarihi zorunludur');
                  return;
                }

                final gunlukKapasite = _parseDouble(kapasiteController.text);
                if (gunlukKapasite == null || gunlukKapasite <= 0) {
                  ctx.showErrorSnackBar('Günlük üretim kapasitesi zorunludur');
                  return;
                }

                final seciliModel = _modeller.firstWhere(
                  (m) => m['id']?.toString() == seciliModelId,
                  orElse: () => <String, dynamic>{},
                );
                final toplamAdet =
                    ((seciliModel['toplam_adet'] ?? seciliModel['adet'] ?? 0)
                                as num?)
                            ?.toInt() ??
                        0;
                final gunSayisi = _calismaGunSayisi(
                  baslangic!,
                  bitis!,
                  seciliCalismaGunleri,
                );
                if (gunSayisi <= 0) {
                  ctx.showErrorSnackBar('En az 1 çalışma günü seçmelisiniz');
                  return;
                }

                final gereken =
                    _gerekenGunlukAdetByGunSayisi(toplamAdet, gunSayisi);

                if (gunlukKapasite < gereken) {
                  final devam = await showDialog<bool>(
                    context: ctx,
                    builder: (warnCtx) => AlertDialog(
                      title: const Text('Kapasite Uyarısı'),
                      content: Text(
                        'Bu plan için gereken günlük üretim ${_formatDecimal(gereken)} adet/gün. '
                        'Girilen kapasite ${_formatDecimal(gunlukKapasite)} adet/gün. '
                        'Yine de kaydedilsin mi?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(warnCtx, false),
                          child: const Text('Vazgeç'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(warnCtx, true),
                          child: const Text('Yine de Kaydet'),
                        ),
                      ],
                    ),
                  );

                  if (devam != true) {
                    return;
                  }
                }

                final ok = await _kaydetPlan(
                  kayit: kayit,
                  modelId: seciliModelId!,
                  asamaKodu: seciliAsamaKodu!,
                  tedarikciId: seciliTedarikciId,
                  baslangic: baslangic!,
                  bitis: bitis!,
                  durum: seciliDurum,
                  tedarikciGunlukKapasite: gunlukKapasite,
                  finalTarih: finalTarih,
                );

                if (ok && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    kapasiteController.dispose();
  }

  List<Map<String, dynamic>> _modelBazliKayitlar(
      List<Map<String, dynamic>> kaynak) {
    final byModel = <String, List<Map<String, dynamic>>>{};
    for (final k in kaynak) {
      final modelId = k['model_id']?.toString();
      if (modelId == null || modelId.isEmpty) continue;
      byModel.putIfAbsent(modelId, () => []).add(k);
    }

    final modelRows = <Map<String, dynamic>>[];
    for (final entry in byModel.entries) {
      final satirlar = entry.value;
      satirlar.sort((a, b) {
        final aSira = _asamaSira(a['asama_kodu']?.toString() ?? '');
        final bSira = _asamaSira(b['asama_kodu']?.toString() ?? '');
        return aSira.compareTo(bSira);
      });

      final dokuma = satirlar.firstWhere(
        (s) => s['asama_kodu']?.toString() == 'dokuma',
        orElse: () => satirlar.first,
      );

      final asamaKayitlari = <String, Map<String, dynamic>>{};
      for (final s in satirlar) {
        final kod = s['asama_kodu']?.toString();
        if (kod == null || kod.isEmpty) continue;
        asamaKayitlari[kod] = s;
      }

      // Model satiri sadece ilk asama (dokuma) planlandiktan sonra gorunsun.
      if (!asamaKayitlari.containsKey('dokuma')) {
        continue;
      }

      String? sonrakiAsama;
      for (final asama in _asamalar) {
        final kod = asama['kod']!;
        if (!asamaKayitlari.containsKey(kod)) {
          sonrakiAsama = kod;
          break;
        }
      }

      final ozet = _asamalar.map((a) {
        final kod = a['kod']!;
        final kayit = asamaKayitlari[kod];
        final durum = (kayit?['durum'] ?? '-').toString();
        return '${a['ad']}: $durum';
      }).join(' | ');

      modelRows.add({
        ...dokuma,
        'asama_kayitlari': asamaKayitlari,
        'asama_ozet': ozet,
        'sonraki_asama_kodu': sonrakiAsama,
      });
    }

    modelRows.sort((a, b) => (a['model_kodu'] ?? '')
        .toString()
        .compareTo((b['model_kodu'] ?? '').toString()));
    return modelRows;
  }

  Widget _buildAsamaButtons(Map<String, dynamic> modelRow,
      {bool compact = false}) {
    final asamaKayitlariRaw = modelRow['asama_kayitlari'];
    final asamaKayitlari =
        asamaKayitlariRaw is Map ? asamaKayitlariRaw : const <String, dynamic>{};
    final modelId = modelRow['model_id']?.toString();

    final mevcutAsamalar = _asamalar
        .where((a) => asamaKayitlari.containsKey(a['kod']))
        .toList()
      ..sort((a, b) => _asamaSira(a['kod']!).compareTo(_asamaSira(b['kod']!)));

    final secilebilirAsamalar = _asamalar
        .where((a) => !asamaKayitlari.containsKey(a['kod']))
        .toList();

    String ozet;
    if (mevcutAsamalar.isEmpty) {
      ozet = 'Henüz aşama planlanmadı';
    } else {
      final sonAsama = mevcutAsamalar.last;
      final sonKayit = asamaKayitlari[sonAsama['kod']];
      final sonDurum = (sonKayit is Map)
          ? (sonKayit['durum'] ?? '-').toString()
          : '-';
      ozet = 'Son aşama: ${sonAsama['ad']} ($sonDurum)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ozet,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (modelId == null || modelId.isEmpty)
          const Text('-')
        else if (secilebilirAsamalar.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Tüm aşamalar planlandı',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: const Color(0xFF166534),
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            tooltip: 'Sonraki üretim aşaması seç',
            onSelected: (kod) => _showPlanDialog(
              modelId: modelId,
              asamaKodu: kod,
              lockModel: true,
              lockAsama: true,
            ),
            itemBuilder: (ctx) => secilebilirAsamalar
                .map(
                  (a) => PopupMenuItem<String>(
                    value: a['kod'],
                    child: Text('${a['ad']} planla'),
                  ),
                )
                .toList(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Sonraki Aşamayı Seç',
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<bool> _kaydetPlan({
    required String modelId,
    required String asamaKodu,
    required dynamic tedarikciId,
    required DateTime baslangic,
    required DateTime bitis,
    required String durum,
    required double tedarikciGunlukKapasite,
    DateTime? finalTarih,
    Map<String, dynamic>? kayit,
  }) async {
    try {
      final asama = _asamalar.firstWhere((a) => a['kod'] == asamaKodu);
      final tablo = asama['tablo']!;

      final model = _modeller.where((m) => m['id']?.toString() == modelId);
      final modelData = model.isNotEmpty ? model.first : null;
      final talepAdedi = ((modelData?['toplam_adet'] ?? modelData?['adet'] ?? 0)
                  as num?)
              ?.toInt() ??
          0;

      final basePayload = <String, dynamic>{
        'model_id': modelId,
        'firma_id': _firmaId,
        'tedarikci_id': _normalizeTedarikciId(tedarikciId),
        'uretim_baslangic_tarihi': baslangic.toIso8601String(),
        'planlanan_bitis_tarihi': bitis.toIso8601String(),
      };

      final durumAdaylari = _durumAdaylari(durum);

      final kayitId = kayit?['id']?.toString();
      if (kayitId != null && kayitId.isNotEmpty) {
        dynamic lastDurumErr;
        var updateOk = false;
        for (final durumDb in durumAdaylari) {
          try {
            await _supabase
                .from(tablo)
                .update({...basePayload, 'durum': durumDb})
                .eq('firma_id', _firmaId)
                .eq('id', kayitId);
            updateOk = true;
            break;
          } on PostgrestException catch (e) {
            if (_isDurumConstraintError(e)) {
              lastDurumErr = e;
              continue;
            }
            rethrow;
          }
        }
        if (!updateOk) {
          throw lastDurumErr ?? 'Durum alanı doğrulanamadı';
        }
      } else {
        final nowIso = DateTime.now().toIso8601String();
        dynamic lastError;
        var basarili = false;
        for (final durumDb in durumAdaylari) {
          final denemeler = <Map<String, dynamic>>[
            {
              ...basePayload,
              'durum': durumDb,
              'atama_tarihi': nowIso,
              'talep_edilen_adet': talepAdedi,
              'tamamlanan_adet': 0,
              'fire_adet': 0,
            },
            {
              ...basePayload,
              'durum': durumDb,
              'atama_tarihi': nowIso,
              'talep_edilen_adet': talepAdedi,
              'tamamlanan_adet': 0,
            },
            {
              ...basePayload,
              'durum': durumDb,
              'talep_edilen_adet': talepAdedi,
              'tamamlanan_adet': 0,
            },
            {
              ...basePayload,
              'durum': durumDb,
              'tamamlanan_adet': 0,
            },
            {
              ...basePayload,
              'durum': durumDb,
            },
          ];

          for (final payload in denemeler) {
            try {
              await _supabase.from(tablo).insert(payload);
              basarili = true;
              break;
            } on PostgrestException catch (e) {
              lastError = e;
              if (_isDurumConstraintError(e)) {
                continue;
              }
            } catch (e) {
              lastError = e;
            }
          }

          if (basarili) {
            break;
          }
        }

        if (!basarili) {
          throw lastError ?? 'Plan kaydı eklenemedi';
        }
      }

      await _kaydetTedarikciModelKapasitesi(
        tedarikciId: tedarikciId,
        modelId: modelId,
        gunlukKapasite: tedarikciGunlukKapasite,
      );

      if (finalTarih != null) {
        await _kaydetModelFinalTarihi(modelId: modelId, finalTarih: finalTarih);
      }

      await _loadData();

      if (!mounted) return false;
      context.showSuccessSnackBar('Üretim planı kaydedildi');
      return true;
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Plan kaydı hatası: $e');
      }
      return false;
    }
  }

  Future<void> _silPlan(Map<String, dynamic> kayit) async {
    final kayitId = kayit['id']?.toString();
    final tablo = kayit['asama_tablo']?.toString();
    if (kayitId == null || tablo == null) {
      context.showErrorSnackBar('Plan kaydı bilgisi eksik');
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan Kaydını Sil'),
        content: const Text('Bu plan satırı silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      await _supabase
          .from(tablo)
          .delete()
          .eq('firma_id', _firmaId)
          .eq('id', kayitId);

      await _loadData();
      if (mounted) context.showSuccessSnackBar('Plan kaydı silindi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Plan silme hatası: $e');
    }
  }

  Widget _buildPanel({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: child,
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> kayitlar) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 920) {
          return Column(
            children: kayitlar.map((k) {
              final durum = (k['durum'] ?? 'planlandi').toString();
              final renk = _durumColor(durum);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${k['model_marka'] ?? '-'} - ${k['model_kodu'] ?? '-'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: renk.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            durum,
                            style: TextStyle(
                              color: renk,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Marka: ${k['model_marka'] ?? '-'}'),
                    Text('Model: ${k['model_kodu'] ?? '-'}'),
                    Text('Renk: ${k['model_renk'] ?? '-'}'),
                    Text('Karışım: ${k['model_karisim'] ?? '-'}'),
                    Text('Adet: ${(k['model_adet'] ?? 0).toString()}'),
                    Text('Termin: ${_formatDate(k['termin_tarihi'])}'),
                    Text('Kaşe Durumu: ${k['kase_durumu'] ?? '-'}'),
                    Text('İplik Tedarikçisi: ${k['iplik_tedarikcisi'] ?? '-'}'),
                    Text('Dokuma: ${k['dokuma_durum'] ?? '-'}'),
                    Text('Dokuma Tedarikçisi: ${k['dokuma_tedarikci'] ?? '-'}'),
                    Text('Başlangıç: ${_formatDate(k['uretim_baslangic_tarihi'])}'),
                    Text('Bitiş: ${_formatDate(k['planlanan_bitis_tarihi'])}'),
                    Text('Diğer Aşamalar: ${k['diger_asamalar'] ?? '-'}'),
                    Text('Final Tarihi: ${_formatDate(k['final_tarihi'])}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Aşamalar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    _buildAsamaButtons(k),
                    Builder(builder: (_) {
                      final bas = _parseDate(k['uretim_baslangic_tarihi']);
                      final bit = _parseDate(k['planlanan_bitis_tarihi']);
                      if (bas == null || bit == null) {
                        return const SizedBox.shrink();
                      }
                      final toplam = (k['model_adet'] as num?)?.toInt() ?? 0;
                      final gereken = _gerekenGunlukAdet(toplam, bas, bit);
                      final kapasite = _parseDouble(k['tedarikci_gunluk_kapasite']);
                      final kapasiteText = kapasite == null
                          ? '-'
                          : '${_formatDecimal(kapasite)} adet/gün';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Gereksinimi: ${_formatDecimal(gereken)} adet/gün',
                          ),
                          Text('Kapasite: $kapasiteText'),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Düzenle',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showPlanDialog(kayit: k),
                        ),
                        IconButton(
                          tooltip: 'Sil',
                          icon: const Icon(Icons.delete_outline),
                          color: const Color(0xFFDC2626),
                          onPressed: () => _silPlan(k),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        return _buildPanel(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 520,
            child: Scrollbar(
              controller: _tableVerticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _tableVerticalScrollController,
                primary: false,
                child: Scrollbar(
                  controller: _tableHorizontalScrollController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _tableHorizontalScrollController,
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                  dataRowMinHeight: 86,
                  dataRowMaxHeight: 96,
              columnSpacing: 20,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('Marka')),
                DataColumn(label: Text('Model')),
                DataColumn(label: Text('Renk')),
                DataColumn(label: Text('Karışım')),
                DataColumn(label: Text('Adet')),
                DataColumn(label: Text('Termin')),
                DataColumn(label: Text('Kaşe Durumu')),
                DataColumn(label: Text('İplik Tedarikçisi')),
                DataColumn(label: Text('Dokuma')),
                DataColumn(label: Text('Dokuma Tedarikçisi')),
                DataColumn(label: Text('Başlangıç')),
                DataColumn(label: Text('Bitiş')),
                DataColumn(label: Text('Diğer Aşamalar')),
                DataColumn(label: Text('Final Tarihi')),
                DataColumn(label: Text('Aşamalar')),
                DataColumn(label: Text('Günlük Plan/Kapasite')),
                DataColumn(label: Text('Durum')),
                DataColumn(label: Text('İşlem')),
              ],
              rows: kayitlar.map((k) {
                final durum = (k['durum'] ?? 'planlandi').toString();
                final renk = _durumColor(durum);
                final bas = _parseDate(k['uretim_baslangic_tarihi']);
                final bit = _parseDate(k['planlanan_bitis_tarihi']);
                final toplam = (k['model_adet'] as num?)?.toInt() ?? 0;
                final gereken =
                    bas == null || bit == null ? null : _gerekenGunlukAdet(toplam, bas, bit);
                final kapasite = _parseDouble(k['tedarikci_gunluk_kapasite']);
                final yetersiz = gereken != null && kapasite != null && kapasite < gereken;
                return DataRow(cells: [
                  DataCell(SizedBox(
                    width: 120,
                    child: Text(
                      (k['model_marka'] ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 160,
                    child: Text(
                      (k['model_kodu'] ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 110,
                    child: Text(
                      (k['model_renk'] ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 120,
                    child: Text(
                      (k['model_karisim'] ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(Text(((k['model_adet'] ?? 0) as num).toInt().toString())),
                  DataCell(Text(_formatDate(k['termin_tarihi']))),
                  DataCell(Text((k['kase_durumu'] ?? '-').toString())),
                  DataCell(SizedBox(
                    width: 140,
                    child: Text(
                      (k['iplik_tedarikcisi'] ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(Text((k['dokuma_durum'] ?? '-').toString())),
                  DataCell(SizedBox(
                    width: 160,
                    child: Text(
                      (k['dokuma_tedarikci'] ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(Text(_formatDate(k['uretim_baslangic_tarihi']))),
                  DataCell(Text(_formatDate(k['planlanan_bitis_tarihi']))),
                  DataCell(SizedBox(
                    width: 260,
                    child: Text(
                      (k['diger_asamalar'] ?? '-').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(Text(_formatDate(k['final_tarihi']))),
                  DataCell(SizedBox(
                    width: 360,
                    child: _buildAsamaButtons(k, compact: true),
                  )),
                  DataCell(SizedBox(
                    width: 180,
                    child: Text(
                      gereken == null
                          ? '-'
                          : '${_formatDecimal(gereken)} / ${kapasite == null ? '-' : _formatDecimal(kapasite)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: yetersiz
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  )),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: renk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      durum,
                      style: TextStyle(
                        color: renk,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Düzenle',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: const Color(0xFF2563EB),
                        onPressed: () => _showPlanDialog(kayit: k),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: const Color(0xFFDC2626),
                        onPressed: () => _silPlan(k),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final kayitlar = _filtreliKayitlar;
    final modelBazliKayitlar = _modelBazliKayitlar(kayitlar);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Üretim Planı'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.unknown,
          },
        ),
        child: Scrollbar(
          controller: _pageScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _pageScrollController,
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
          children: [
            _buildPanel(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.view_timeline,
                        color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Üretim Planı',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Model bazlı aşama, tedarikçi ve başlangıç/bitiş planı',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showPlanDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Yeni Plan'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loadData,
                    tooltip: 'Yenile',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPanel(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Model, aşama, tedarikçi veya durum ara',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _arama = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${modelBazliKayitlar.length} model planı',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_yukleniyor)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingWidget(),
              )
            else if (modelBazliKayitlar.isEmpty)
              _buildPanel(
                child: const SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note, size: 46, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Henüz üretim planı oluşturulmamış'),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildTable(modelBazliKayitlar),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
