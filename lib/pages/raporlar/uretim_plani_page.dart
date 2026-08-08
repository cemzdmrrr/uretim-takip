import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/responsive_horizontal_table.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:uretim_takip/utils/excel_export.dart';
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
  bool _kontrolModu = false;
  int _aktifSekme = 0;
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
      final durum = (k['durum'] ?? '').toString().toLowerCase();
      return model.contains(q) ||
          marka.contains(q) ||
          renk.contains(q) ||
          karisim.contains(q) ||
          iplikTed.contains(q) ||
          asama.contains(q) ||
          tedarikci.contains(q) ||
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
                  'id, model_id, tedarikci_id, uretim_baslangic_tarihi, planlanan_bitis_tarihi, durum, talep_edilen_adet, adet, kabul_edilen_adet, tamamlanan_adet, created_at')
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
              'model_tamamlanan_adet': ((model?['yuklenen_adet'] ??
                          model?['tamamlanan_adet'] ??
                          0) as num?)
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

      final kayitlar = latest.values.map((satir) {
        final modelId = satir['model_id']?.toString() ?? '';
        final model = modelIndex[modelId];
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
    final tedarikci = _tedarikciler.firstWhere(
      (t) => t['id']?.toString() == tedarikciId?.toString(),
      orElse: () => <String, dynamic>{},
    );
    final firmaKapasitesi = _parseDouble(tedarikci['gunluk_uretim_kapasitesi']);
    if (firmaKapasitesi != null && firmaKapasitesi > 0) {
      return firmaKapasitesi;
    }

    final key = _kapasiteKey(tedarikciId, modelId);
    if (key != null && _tedarikciModelKapasiteMap.containsKey(key)) {
      return _tedarikciModelKapasiteMap[key];
    }

    return null;
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
    return model?['final_tarihi'] ??
        model?['final_tarih'] ??
        model?['teslim_tarihi'];
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

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    final s = value?.toString().trim() ?? '';
    if (s.isEmpty) return 0;
    return int.tryParse(s) ?? 0;
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

  double _gerekenGunlukAdetByGunSayisi(int toplamAdet, int gunSayisi) {
    if (gunSayisi <= 0) return 0;
    return toplamAdet / gunSayisi;
  }

  bool _isMissingColumnError(PostgrestException e, String column) {
    if (e.code != '42703') return false;
    final mesaj =
        '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
    return mesaj.contains(column.toLowerCase());
  }

  bool _isMissingRelationError(PostgrestException e, String relation) {
    if (e.code != '42P01' && e.code != 'PGRST205') return false;
    final mesaj =
        '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
    final relationLower = relation.toLowerCase();
    return mesaj.contains(relationLower) ||
        mesaj.contains('public.$relationLower') ||
        mesaj.contains('could not find the table');
  }

  bool _isDurumConstraintError(PostgrestException e) {
    if (e.code != '23514') return false;
    final mesaj =
        '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
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
                final list = secili.map((s) => DateTime.parse(s)).toList()
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

  String _durumAnahtari(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll(' ', '_');
  }

  bool _tamamlanmisDurumMu(String durum) {
    return {
      'tamamlandi',
      'tamamlandi.',
      'sevk_edildi',
      'sevkedildi',
      'kapandi',
      'completed',
    }.contains(_durumAnahtari(durum));
  }

  bool _pasifPlanDurumuMu(String durum) {
    return {
      'iptal',
      'iptal_edildi',
      'reddedildi',
      'red',
      'cancelled',
      'canceled',
    }.contains(_durumAnahtari(durum));
  }

  bool _islemdeDurumMu(String durum) {
    return {
      'baslandi',
      'baslatildi',
      'uretimde',
      'devam_ediyor',
      'islemde',
      'isleniyor',
      'kismi_tamamlandi',
      'sevk_ediliyor',
    }.contains(_durumAnahtari(durum));
  }

  List<Map<String, dynamic>> _planKontrolKayitlari(Map<String, dynamic> kayit) {
    final asamaKayitlariRaw = kayit['asama_kayitlari'];
    if (asamaKayitlariRaw is Map) {
      return asamaKayitlariRaw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [kayit];
  }

  DateTime _gunBaslangici(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  int _kontrolIsGunuSayisi(
    DateTime baslangic,
    DateTime bitis, {
    bool bitisDahil = true,
  }) {
    final start = _gunBaslangici(baslangic);
    final end = _gunBaslangici(bitis);
    if (end.isBefore(start)) return 0;

    var sayi = 0;
    var cursor = start;
    while (cursor.isBefore(end) || (bitisDahil && cursor == end)) {
      if (!_isWeekend(cursor)) sayi++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return sayi;
  }

  int _kontrolHedefAdet(Map<String, dynamic> planKaydi) {
    final kabul = _toInt(planKaydi['kabul_edilen_adet']);
    if (kabul > 0) return kabul;
    return _planlananAdet(planKaydi);
  }

  int _kontrolTamamlananAdet(Map<String, dynamic> planKaydi, int hedefAdet) {
    final tamamlanan = _toInt(planKaydi['tamamlanan_adet']);
    if (tamamlanan > 0) return tamamlanan > hedefAdet ? hedefAdet : tamamlanan;
    if (_tamamlanmisDurumMu(planKaydi['durum']?.toString() ?? '')) {
      return hedefAdet;
    }
    return 0;
  }

  List<String> _planKontrolUyarilari(Map<String, dynamic> kayit) {
    final bugunBaslangic = _gunBaslangici(DateTime.now());
    final uyarilar = <String>[];

    for (final planKaydi in _planKontrolKayitlari(kayit)) {
      final baslangic = _parseDate(planKaydi['uretim_baslangic_tarihi']);
      final bitis = _parseDate(planKaydi['planlanan_bitis_tarihi']);
      final asama = planKaydi['asama_adi']?.toString() ?? 'Aşama';

      final durum = _durumAnahtari(planKaydi['durum']);
      if (_pasifPlanDurumuMu(durum)) continue;
      final tamamlandi = _tamamlanmisDurumMu(durum);
      final islemde = _islemdeDurumMu(durum);

      if (baslangic == null || bitis == null) {
        uyarilar.add('$asama: plan başlangıç/bitiş tarihi eksik');
        continue;
      }

      final baslangicGunu = _gunBaslangici(baslangic);
      final bitisGunu = _gunBaslangici(bitis);

      if (bitisGunu.isBefore(baslangicGunu)) {
        uyarilar.add('$asama: bitiş tarihi başlangıçtan önce');
        continue;
      }

      if (bitisGunu.isBefore(bugunBaslangic) && !tamamlandi) {
        uyarilar.add('$asama: bitiş tarihi geçti, aşama tamamlanmadı');
        continue;
      }

      if (baslangicGunu.isBefore(bugunBaslangic) && !islemde && !tamamlandi) {
        uyarilar.add('$asama: başlangıç tarihi geçti, üretim başlamadı');
        continue;
      }

      if (islemde && bugunBaslangic.isAfter(baslangicGunu)) {
        final toplamGun = _kontrolIsGunuSayisi(baslangicGunu, bitisGunu);
        final gecenGun = _kontrolIsGunuSayisi(
          baslangicGunu,
          bugunBaslangic.subtract(const Duration(days: 1)),
        );
        final hedefAdet = _kontrolHedefAdet(planKaydi);
        if (toplamGun > 0 && gecenGun > 0 && hedefAdet > 0) {
          final beklenenAdet = (hedefAdet * gecenGun / toplamGun).ceil();
          final tamamlananAdet = _kontrolTamamlananAdet(planKaydi, hedefAdet);
          if (tamamlananAdet < beklenenAdet) {
            uyarilar.add(
              '$asama: üretim ilerlemesi geride ($tamamlananAdet/$beklenenAdet)',
            );
          }
        }
      }
    }

    return uyarilar;
  }

  bool _planaUygunDegilMi(Map<String, dynamic> kayit) {
    return _planKontrolUyarilari(kayit).isNotEmpty;
  }

  Future<void> _kontrolModunuDegistir() async {
    final aciliyor = !_kontrolModu;
    setState(() => _kontrolModu = aciliyor);

    if (!aciliyor) return;

    await _loadData();
    if (!mounted) return;

    final sapmaSayisi =
        _modelBazliKayitlar(_filtreliKayitlar).where(_planaUygunDegilMi).length;
    if (sapmaSayisi > 0) {
      context.showErrorSnackBar(
        '$sapmaSayisi model plan kontrolünde uygunsuz görünüyor',
      );
    } else {
      context.showSuccessSnackBar('Plan kontrolünde uygunsuz model bulunmadı');
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

  Future<void> _kaydetTedarikciKapasitesi({
    required dynamic tedarikciId,
    required double gunlukKapasite,
  }) async {
    final normalizedId = _normalizeTedarikciId(tedarikciId);
    if (normalizedId == null) return;

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
      throw 'Tedarikçiler tablosunda gunluk_uretim_kapasitesi kolonu bulunamadı';
    }

    final idx = _tedarikciler
        .indexWhere((t) => t['id']?.toString() == normalizedId.toString());
    if (idx >= 0) {
      _tedarikciler[idx]['gunluk_uretim_kapasitesi'] = gunlukKapasite;
    }
  }

  Future<void> _showKapasiteYonetimiDialog() async {
    dynamic seciliTedarikciId =
        _tedarikciler.isNotEmpty ? _tedarikciler.first['id'] : null;
    final kapasiteController = TextEditingController();

    void mevcutKapasiteyiYaz() {
      final tedarikci = _tedarikciler.firstWhere(
        (t) => t['id']?.toString() == seciliTedarikciId?.toString(),
        orElse: () => <String, dynamic>{},
      );
      final kapasite = _parseDouble(tedarikci['gunluk_uretim_kapasitesi']);
      kapasiteController.text =
          kapasite == null ? '' : _formatDecimal(kapasite);
    }

    mevcutKapasiteyiYaz();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final kapasiteSatirlari = _kapasiteSatirlari();
          return AlertDialog(
            title: const Text('Firma Günlük Üretim Kapasiteleri'),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<dynamic>(
                            key: ValueKey(
                              seciliTedarikciId?.toString() ?? 'firma-yok',
                            ),
                            initialValue: seciliTedarikciId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Üretim yapan firma *',
                              border: OutlineInputBorder(),
                            ),
                            items: _tedarikciler
                                .map((t) => DropdownMenuItem<dynamic>(
                                      value: t['id'],
                                      child: Text(
                                        _tedarikciEtiket(t),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                seciliTedarikciId = value;
                                mevcutKapasiteyiYaz();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kapasiteController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Günlük üretim adedi *',
                        hintText: 'Örn: 250',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tanımlı Kapasiteler',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (kapasiteSatirlari.isEmpty)
                      const Text('Henüz kapasite tanımı yok')
                    else
                      ...kapasiteSatirlari.map(
                        (satir) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            satir['firma']?.toString() ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text(
                            'Revize etmek için seç',
                            style: TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            setDialogState(() {
                              seciliTedarikciId = satir['tedarikci_id'];
                              kapasiteController.text = _formatDecimal(
                                satir['kapasite'] as double,
                              );
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_formatDecimal(satir['kapasite'] as double)} adet/gün',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Kapat'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (seciliTedarikciId == null) {
                    ctx.showErrorSnackBar('Firma seçin');
                    return;
                  }
                  final kapasite = _parseDouble(kapasiteController.text);
                  if (kapasite == null || kapasite <= 0) {
                    ctx.showErrorSnackBar('Geçerli günlük üretim adedi girin');
                    return;
                  }
                  try {
                    await _kaydetTedarikciKapasitesi(
                      tedarikciId: seciliTedarikciId,
                      gunlukKapasite: kapasite,
                    );
                    if (!mounted) return;
                    setDialogState(() {});
                    context.showSuccessSnackBar('Kapasite kaydedildi');
                  } catch (e) {
                    if (!mounted) return;
                    context.showErrorSnackBar('Kapasite kaydedilemedi: $e');
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );

    kapasiteController.dispose();
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _kapasiteSatirlari() {
    final rows = _tedarikciler
        .map((tedarikci) {
          final kapasite = _parseDouble(tedarikci['gunluk_uretim_kapasitesi']);
          if (kapasite == null || kapasite <= 0) return null;
          return {
            'tedarikci_id': tedarikci['id'],
            'firma': _tedarikciEtiket(tedarikci),
            'kapasite': kapasite,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
    rows.sort((a, b) {
      return a['firma'].toString().compareTo(b['firma'].toString());
    });
    return rows;
  }

  Future<void> _kaydetModelFinalTarihi({
    required String modelId,
    required DateTime finalTarih,
  }) async {
    final alanlar = ['final_tarihi', 'final_tarih', 'teslim_tarihi'];
    // Bu alanlar veritabaninda DATE tipindedir. Saat bilgisi iceren ISO-8601
    // degeri gondermek, ozellikle mevcut `teslim_tarihi` fallback alaninda
    // "invalid input syntax for type date" hatasina neden olur.
    final tarihDegeri = DateFormat('yyyy-MM-dd').format(finalTarih);

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
      seciliCalismaGunleri = _dateRangeDays(baslangic!, bitis!)
          .where((d) => !_isWeekend(d))
          .toList();
    }

    varsayilanCalismaGunleriniKur();

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
          title: Text(
              kayit == null ? 'Yeni Üretim Planı' : 'Üretim Planı Düzenle'),
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
                              initialDate:
                                  bitis ?? (baslangic ?? DateTime.now()),
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
                              setStateDialog(
                                  () => seciliCalismaGunleri = sonuc);
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
                  if (seciliAsamaKodu == 'utu' ||
                      seciliAsamaKodu == 'paketleme')
                    Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  finalTarih ?? (bitis ?? DateTime.now()),
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
                  Builder(builder: (_) {
                    final seciliModel = _modeller.firstWhere(
                      (m) => m['id']?.toString() == seciliModelId,
                      orElse: () => <String, dynamic>{},
                    );
                    final toplamAdet = ((seciliModel['toplam_adet'] ??
                                seciliModel['adet'] ??
                                0) as num?)
                            ?.toInt() ??
                        0;
                    final kapasite = _getPlanKapasitesi(
                      tedarikciId: seciliTedarikciId,
                      modelId: seciliModelId,
                    );
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
                    final renk = yetersiz
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF166534);

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
                                ? 'Firma/model günlük kapasitesi tanımlı değil'
                                : (yetersiz
                                    ? 'Kapasite yetersiz (${_formatDecimal(kapasite)} adet/gün)'
                                    : 'Kapasite yeterli (${_formatDecimal(kapasite)} adet/gün)'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kapasite == null
                                  ? const Color(0xFFB45309)
                                  : renk,
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
                  ctx.showErrorSnackBar(
                      'Bitiş tarihi başlangıçtan önce olamaz');
                  return;
                }

                if ((seciliAsamaKodu == 'utu' ||
                        seciliAsamaKodu == 'paketleme') &&
                    finalTarih == null) {
                  ctx.showErrorSnackBar(
                      'Ütü/Paketleme sonrası final tarihi zorunludur');
                  return;
                }

                final kayitId = kayit?['id']?.toString();
                final ayniAsamadaPlanVar = _kayitlar.any((plan) {
                  final planId = plan['id']?.toString();
                  return plan['model_id']?.toString() == seciliModelId &&
                      plan['asama_kodu']?.toString() == seciliAsamaKodu &&
                      (kayitId == null || planId != kayitId);
                });
                if (ayniAsamadaPlanVar) {
                  ctx.showErrorSnackBar(
                      'Bu model için seçilen aşamada zaten plan var');
                  return;
                }

                final seciliModel = _modeller.firstWhere(
                  (m) => m['id']?.toString() == seciliModelId,
                  orElse: () => <String, dynamic>{},
                );
                final toplamAdet = ((seciliModel['toplam_adet'] ??
                            seciliModel['adet'] ??
                            0) as num?)
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
                final gunlukKapasite = _getPlanKapasitesi(
                  tedarikciId: seciliTedarikciId,
                  modelId: seciliModelId,
                );

                if (gunlukKapasite != null && gunlukKapasite < gereken) {
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

      final dokumaKaydi = asamaKayitlari['dokuma'];
      final konfeksiyonKaydi = asamaKayitlari['konfeksiyon'];
      final utuPaketFirmaKaydi =
          asamaKayitlari['paketleme'] ?? asamaKayitlari['utu'];
      final utuTarihKaydi =
          asamaKayitlari['utu'] ?? asamaKayitlari['paketleme'];

      final toplamAdet = _toInt(dokuma['model_adet']);
      var tamamlananAdet = _toInt(dokuma['model_tamamlanan_adet']);
      if (tamamlananAdet < 0) tamamlananAdet = 0;
      if (toplamAdet > 0 && tamamlananAdet > toplamAdet) {
        tamamlananAdet = toplamAdet;
      }
      final kalanAdet =
          toplamAdet > tamamlananAdet ? toplamAdet - tamamlananAdet : 0;

      modelRows.add({
        ...dokuma,
        'asama_kayitlari': asamaKayitlari,
        'tamamlanan_adet': tamamlananAdet,
        'kalan_adet': kalanAdet,
        'dokuma_firma': (dokumaKaydi?['tedarikci_adi'] ?? '-').toString(),
        'dokuma_baslangic_tarihi': dokumaKaydi?['uretim_baslangic_tarihi'],
        'dokuma_bitis_tarihi': dokumaKaydi?['planlanan_bitis_tarihi'],
        'konfeksiyon_firma':
            (konfeksiyonKaydi?['tedarikci_adi'] ?? '-').toString(),
        'konfeksiyon_baslangic_tarihi':
            konfeksiyonKaydi?['uretim_baslangic_tarihi'],
        'konfeksiyon_bitis_tarihi': konfeksiyonKaydi?['planlanan_bitis_tarihi'],
        'utu_paket_firma':
            (utuPaketFirmaKaydi?['tedarikci_adi'] ?? '-').toString(),
        'utu_baslangic_tarihi': utuTarihKaydi?['uretim_baslangic_tarihi'],
        'utu_bitis_tarihi': utuTarihKaydi?['planlanan_bitis_tarihi'],
      });
    }

    modelRows.sort((a, b) => (a['model_kodu'] ?? '')
        .toString()
        .compareTo((b['model_kodu'] ?? '').toString()));
    return modelRows;
  }

  List<Map<String, dynamic>> _firmaBazliKayitlar(
      List<Map<String, dynamic>> kaynak) {
    final byFirma = <String, List<Map<String, dynamic>>>{};
    for (final kayit in kaynak) {
      final firma = (kayit['tedarikci_adi'] ?? '-').toString().trim();
      final key = firma.isEmpty ? '-' : firma;
      byFirma.putIfAbsent(key, () => []).add(kayit);
    }

    final firmaRows = <Map<String, dynamic>>[];
    for (final entry in byFirma.entries) {
      final satirlar = List<Map<String, dynamic>>.from(entry.value)
        ..sort((a, b) {
          final modelCompare = (a['model_kodu'] ?? '')
              .toString()
              .compareTo((b['model_kodu'] ?? '').toString());
          if (modelCompare != 0) return modelCompare;
          return _asamaSira(a['asama_kodu']?.toString() ?? '')
              .compareTo(_asamaSira(b['asama_kodu']?.toString() ?? ''));
        });

      final toplamAdet = satirlar.fold<int>(
        0,
        (sum, kayit) => sum + _planlananAdet(kayit),
      );
      final modelSayisi = satirlar
          .map((e) => e['model_id']?.toString())
          .where((e) => e != null && e.isNotEmpty)
          .toSet()
          .length;

      firmaRows.add({
        'firma_adi': entry.key,
        'toplam_adet': toplamAdet,
        'model_sayisi': modelSayisi,
        'plan_sayisi': satirlar.length,
        'satirlar': satirlar,
      });
    }

    firmaRows.sort((a, b) => (a['firma_adi'] ?? '')
        .toString()
        .compareTo((b['firma_adi'] ?? '').toString()));
    return firmaRows;
  }

  Future<void> _firmaPlanlariniExcelAktar(
    List<Map<String, dynamic>> firmaRows,
  ) async {
    final excelRows = <Map<String, dynamic>>[];

    for (final firma in firmaRows) {
      final satirlar = List<Map<String, dynamic>>.from(firma['satirlar']);
      for (final kayit in satirlar) {
        excelRows.add({
          'firma': firma['firma_adi']?.toString() ?? '-',
          'model': kayit['model_kodu']?.toString() ?? '-',
          'marka': kayit['model_marka']?.toString() ?? '-',
          'renk': kayit['model_renk']?.toString() ?? '-',
          'asama': kayit['asama_adi']?.toString() ?? '-',
          'plan_adedi': _planlananAdet(kayit),
          'baslangic': _formatDate(kayit['uretim_baslangic_tarihi']),
          'bitis': _formatDate(kayit['planlanan_bitis_tarihi']),
          'durum': kayit['durum']?.toString() ?? '-',
        });
      }
    }

    if (excelRows.isEmpty) {
      context.showErrorSnackBar('Dışa aktarılacak firma planı yok');
      return;
    }

    try {
      await ExcelHelper.exportToExcel(
        data: excelRows,
        fileName:
            'Firma_Planlari_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
        columns: const {
          'firma': 'Firma',
          'model': 'Model',
          'marka': 'Marka',
          'renk': 'Renk',
          'asama': 'Aşama',
          'plan_adedi': 'Plan Adedi',
          'baslangic': 'Başlangıç',
          'bitis': 'Bitiş',
          'durum': 'Durum',
        },
      );
      if (!mounted) return;
      context.showSuccessSnackBar('Firma planları Excel olarak aktarıldı');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Excel aktarımı başarısız: $e');
    }
  }

  int _planlananAdet(Map<String, dynamic> kayit) {
    final talep = _toInt(kayit['talep_edilen_adet']);
    if (talep > 0) return talep;
    final adet = _toInt(kayit['adet']);
    if (adet > 0) return adet;
    return _toInt(kayit['model_adet']);
  }

  Future<void> _showAsamaSecimDialog({
    required String modelId,
    required Map<String, dynamic> asamaKayitlari,
  }) async {
    final secim = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Üretim Aşamaları'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _asamalar.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final asama = _asamalar[i];
              final kod = asama['kod']!;
              final ad = asama['ad']!;
              final mevcut = asamaKayitlari[kod];
              final planli = mevcut != null;
              final durum = planli && mevcut is Map
                  ? (mevcut['durum'] ?? '-').toString()
                  : null;

              return ListTile(
                dense: true,
                enabled: !planli,
                leading: Icon(
                  planli ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: planli
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF2563EB),
                ),
                title: Text(ad),
                subtitle: Text(
                  planli
                      ? 'Mevcut plan var (${durum ?? '-'})'
                      : 'Bu aşamayı planla',
                ),
                trailing: planli
                    ? const Text(
                        'Planlandı',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: planli ? null : () => Navigator.pop(dialogContext, kod),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );

    if (secim == null || !mounted) return;

    await _showPlanDialog(
      modelId: modelId,
      asamaKodu: secim,
      lockModel: true,
      lockAsama: true,
    );
  }

  Widget _buildAsamaButtons(Map<String, dynamic> modelRow,
      {bool compact = false}) {
    final asamaKayitlariRaw = modelRow['asama_kayitlari'];
    final asamaKayitlari = asamaKayitlariRaw is Map
        ? Map<String, dynamic>.from(
            asamaKayitlariRaw.map((k, v) => MapEntry(k.toString(), v)),
          )
        : <String, dynamic>{};
    final modelId = modelRow['model_id']?.toString();

    final mevcutAsamalar = _asamalar
        .where((a) => asamaKayitlari.containsKey(a['kod']))
        .toList()
      ..sort((a, b) => _asamaSira(a['kod']!).compareTo(_asamaSira(b['kod']!)));

    final secilebilirAsamalar =
        _asamalar.where((a) => !asamaKayitlari.containsKey(a['kod'])).toList();

    String ozet;
    if (mevcutAsamalar.isEmpty) {
      ozet = 'Henüz aşama planlanmadı';
    } else {
      final sonAsama = mevcutAsamalar.last;
      final sonKayit = asamaKayitlari[sonAsama['kod']];
      final sonDurum =
          (sonKayit is Map) ? (sonKayit['durum'] ?? '-').toString() : '-';
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
        else ...[
          if (mevcutAsamalar.isNotEmpty)
            Wrap(
              spacing: compact ? 6 : 8,
              runSpacing: compact ? 6 : 8,
              children: mevcutAsamalar.map((asama) {
                final kayit = asamaKayitlari[asama['kod']];
                final planKaydi = kayit is Map
                    ? Map<String, dynamic>.from(kayit)
                    : <String, dynamic>{};
                final baslangic =
                    _formatDate(planKaydi['uretim_baslangic_tarihi']);
                final bitis = _formatDate(planKaydi['planlanan_bitis_tarihi']);
                return Tooltip(
                  message: 'Aşama ve tarihleri düzenle',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: planKaydi.isEmpty
                        ? null
                        : () => _showPlanDialog(
                              kayit: planKaydi,
                              lockModel: true,
                            ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: compact ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            asama['ad'] ?? '-',
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 6),
                            Text(
                              '$baslangic - $bitis',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(width: 5),
                          Icon(
                            Icons.edit_calendar_outlined,
                            size: compact ? 14 : 16,
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          if (mevcutAsamalar.isNotEmpty) const SizedBox(height: 8),
          if (secilebilirAsamalar.isEmpty)
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
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _showAsamaSecimDialog(
                modelId: modelId,
                asamaKayitlari: asamaKayitlari,
              ),
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
      ],
    );
  }

  Future<void> _yeniPlanKaydiEkle({
    required String tablo,
    required Map<String, dynamic> basePayload,
    required List<String> durumAdaylari,
    required int talepAdedi,
  }) async {
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

      if (basarili) break;
    }

    if (!basarili) {
      throw lastError ?? 'Plan kaydı eklenemedi';
    }
  }

  Future<bool> _kaydetPlan({
    required String modelId,
    required String asamaKodu,
    required dynamic tedarikciId,
    required DateTime baslangic,
    required DateTime bitis,
    required String durum,
    DateTime? finalTarih,
    Map<String, dynamic>? kayit,
  }) async {
    try {
      final asama = _asamalar.firstWhere((a) => a['kod'] == asamaKodu);
      final tablo = asama['tablo']!;

      final model = _modeller.where((m) => m['id']?.toString() == modelId);
      final modelData = model.isNotEmpty ? model.first : null;
      final talepAdedi =
          ((modelData?['toplam_adet'] ?? modelData?['adet'] ?? 0) as num?)
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
        final eskiAsamaKodu = kayit?['asama_kodu']?.toString();
        final eskiTablo = kayit?['asama_tablo']?.toString();

        if (eskiAsamaKodu != null &&
            eskiAsamaKodu.isNotEmpty &&
            eskiAsamaKodu != asamaKodu) {
          if (eskiTablo == null || eskiTablo.isEmpty) {
            throw 'Eski aşama tablo bilgisi bulunamadı';
          }

          await _yeniPlanKaydiEkle(
            tablo: tablo,
            basePayload: basePayload,
            durumAdaylari: durumAdaylari,
            talepAdedi: talepAdedi,
          );

          await _supabase
              .from(eskiTablo)
              .delete()
              .eq('firma_id', _firmaId)
              .eq('id', kayitId);
        } else {
          final updateTablo =
              eskiTablo != null && eskiTablo.isNotEmpty ? eskiTablo : tablo;
          dynamic lastDurumErr;
          var updateOk = false;
          for (final durumDb in durumAdaylari) {
            try {
              await _supabase
                  .from(updateTablo)
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
        }
      } else {
        await _yeniPlanKaydiEkle(
          tablo: tablo,
          basePayload: basePayload,
          durumAdaylari: durumAdaylari,
          talepAdedi: talepAdedi,
        );
      }

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
              final kontrolUyarilari =
                  _kontrolModu ? _planKontrolUyarilari(k) : <String>[];
              final kontrolUyarisi = kontrolUyarilari.isNotEmpty;
              final kart = Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      kontrolUyarisi ? const Color(0xFFFFF1F2) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kontrolUyarisi
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFE2E8F0),
                    width: kontrolUyarisi ? 2 : 1,
                  ),
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
                    Text('Model adı: ${k['model_kodu'] ?? '-'}'),
                    Text('Renk: ${k['model_renk'] ?? '-'}'),
                    Text('Karışım: ${k['model_karisim'] ?? '-'}'),
                    Text('Adet: ${(k['model_adet'] ?? 0).toString()}'),
                    Text('Termin: ${_formatDate(k['termin_tarihi'])}'),
                    Text(
                        'Tamamlanan adet: ${(k['tamamlanan_adet'] ?? 0).toString()}'),
                    Text('Kalan adet: ${(k['kalan_adet'] ?? 0).toString()}'),
                    Text('Dokumayı yapan firma: ${k['dokuma_firma'] ?? '-'}'),
                    Text(
                        'Dokuma başlama tarihi: ${_formatDate(k['dokuma_baslangic_tarihi'])}'),
                    Text(
                        'Dokuma bitiş tarihi: ${_formatDate(k['dokuma_bitis_tarihi'])}'),
                    Text(
                        'Konfeksiyon yapan firma: ${k['konfeksiyon_firma'] ?? '-'}'),
                    Text(
                        'Konfeksiyon başlama tarihi: ${_formatDate(k['konfeksiyon_baslangic_tarihi'])}'),
                    Text(
                        'Konfeksiyon bitiş tarihi: ${_formatDate(k['konfeksiyon_bitis_tarihi'])}'),
                    Text(
                        'Ütü paket yapan firma: ${k['utu_paket_firma'] ?? '-'}'),
                    Text(
                        'Ütü başlama tarihi: ${_formatDate(k['utu_baslangic_tarihi'])}'),
                    Text(
                        'Ütü bitiş tarihi: ${_formatDate(k['utu_bitis_tarihi'])}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Aşamalar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    _buildAsamaButtons(k),
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
              if (!kontrolUyarisi) return kart;
              return Tooltip(
                message: kontrolUyarilari.join('\n'),
                child: kart,
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
                        DataColumn(label: Text('Model Adı')),
                        DataColumn(label: Text('Renk')),
                        DataColumn(label: Text('Karışım')),
                        DataColumn(label: Text('Adet')),
                        DataColumn(label: Text('Termin')),
                        DataColumn(label: Text('Tamamlanan Adet')),
                        DataColumn(label: Text('Kalan Adet')),
                        DataColumn(label: Text('Dokumayı Yapan Firma')),
                        DataColumn(label: Text('Dokuma Başlama')),
                        DataColumn(label: Text('Dokuma Bitiş')),
                        DataColumn(label: Text('Konfeksiyon Yapan Firma')),
                        DataColumn(label: Text('Konfeksiyon Başlama')),
                        DataColumn(label: Text('Konfeksiyon Bitiş')),
                        DataColumn(label: Text('Ütü Paket Yapan Firma')),
                        DataColumn(label: Text('Ütü Başlama')),
                        DataColumn(label: Text('Ütü Bitiş')),
                        DataColumn(label: Text('Aşamalar')),
                        DataColumn(label: Text('İşlem')),
                      ],
                      rows: kayitlar.map((k) {
                        final kontrolUyarilari = _kontrolModu
                            ? _planKontrolUyarilari(k)
                            : <String>[];
                        final kontrolUyarisi = kontrolUyarilari.isNotEmpty;
                        return DataRow(
                            color: kontrolUyarisi
                                ? WidgetStateProperty.all(
                                    const Color(0xFFFFF1F2))
                                : null,
                            cells: [
                              DataCell(SizedBox(
                                width: 160,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: kontrolUyarisi
                                        ? Border.all(
                                            color: const Color(0xFFDC2626),
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Tooltip(
                                    message: kontrolUyarisi
                                        ? kontrolUyarilari.join('\n')
                                        : '',
                                    child: Text(
                                      (k['model_kodu'] ?? '-').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: kontrolUyarisi
                                            ? const Color(0xFF991B1B)
                                            : null,
                                      ),
                                    ),
                                  ),
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
                              DataCell(Text(((k['model_adet'] ?? 0) as num)
                                  .toInt()
                                  .toString())),
                              DataCell(Text(_formatDate(k['termin_tarihi']))),
                              DataCell(Text(((k['tamamlanan_adet'] ?? 0) as num)
                                  .toInt()
                                  .toString())),
                              DataCell(Text(((k['kalan_adet'] ?? 0) as num)
                                  .toInt()
                                  .toString())),
                              DataCell(SizedBox(
                                width: 140,
                                child: Text(
                                  (k['dokuma_firma'] ?? '-').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Text(
                                  _formatDate(k['dokuma_baslangic_tarihi']))),
                              DataCell(
                                  Text(_formatDate(k['dokuma_bitis_tarihi']))),
                              DataCell(SizedBox(
                                width: 160,
                                child: Text(
                                  (k['konfeksiyon_firma'] ?? '-').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Text(_formatDate(
                                  k['konfeksiyon_baslangic_tarihi']))),
                              DataCell(Text(
                                  _formatDate(k['konfeksiyon_bitis_tarihi']))),
                              DataCell(SizedBox(
                                width: 170,
                                child: Text(
                                  (k['utu_paket_firma'] ?? '-').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(
                                  Text(_formatDate(k['utu_baslangic_tarihi']))),
                              DataCell(
                                  Text(_formatDate(k['utu_bitis_tarihi']))),
                              DataCell(SizedBox(
                                width: 360,
                                child: _buildAsamaButtons(k, compact: true),
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Düzenle',
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    color: const Color(0xFF2563EB),
                                    onPressed: () => _showPlanDialog(kayit: k),
                                  ),
                                  IconButton(
                                    tooltip: 'Sil',
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
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

  Widget _buildFirmaPlanlari(List<Map<String, dynamic>> firmaRows) {
    if (firmaRows.isEmpty) {
      return _buildPanel(
        child: const SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_outlined, size: 46, color: Colors.grey),
                SizedBox(height: 10),
                Text('Firma bazlı plan kaydı bulunamadı'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: firmaRows.map((firma) {
        final satirlar = List<Map<String, dynamic>>.from(firma['satirlar']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business_outlined,
                                color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firma['firma_adi']?.toString() ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${firma['model_sayisi']} model | ${firma['plan_sayisi']} plan satırı',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _firmaOzetKutusu(
                      'Toplam Adet',
                      '${firma['toplam_adet']} adet',
                      Icons.inventory_2_outlined,
                      const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: satirlar
                            .map((kayit) => _buildFirmaMobilSatir(kayit))
                            .toList(),
                      ),
                    );
                  }

                  return ResponsiveHorizontalTable(
                    minWidth: 1100,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Marka')),
                        DataColumn(label: Text('Renk')),
                        DataColumn(label: Text('Aşama')),
                        DataColumn(label: Text('Plan Adedi')),
                        DataColumn(label: Text('Başlangıç')),
                        DataColumn(label: Text('Bitiş')),
                        DataColumn(label: Text('Durum')),
                      ],
                      rows: satirlar.map((kayit) {
                        return DataRow(cells: [
                          DataCell(_tableCellText(
                              kayit['model_kodu']?.toString() ?? '-',
                              width: 150,
                              bold: true)),
                          DataCell(_tableCellText(
                              kayit['model_marka']?.toString() ?? '-',
                              width: 130)),
                          DataCell(_tableCellText(
                              kayit['model_renk']?.toString() ?? '-',
                              width: 110)),
                          DataCell(_tableCellText(
                              kayit['asama_adi']?.toString() ?? '-',
                              width: 120)),
                          DataCell(Text('${_planlananAdet(kayit)} adet')),
                          DataCell(Text(
                              _formatDate(kayit['uretim_baslangic_tarihi']))),
                          DataCell(Text(
                              _formatDate(kayit['planlanan_bitis_tarihi']))),
                          DataCell(_firmaDurumChip(
                              kayit['durum']?.toString() ?? 'planlandi')),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _firmaOzetKutusu(
      String baslik, String deger, IconData icon, Color renk) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renk.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: renk, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                Text(
                  deger,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmaMobilSatir(Map<String, dynamic> kayit) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
                  '${kayit['model_marka'] ?? '-'} - ${kayit['model_kodu'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _firmaDurumChip(kayit['durum']?.toString() ?? 'planlandi'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _miniPlanBilgi('Renk', kayit['model_renk']?.toString() ?? '-'),
              _miniPlanBilgi('Aşama', kayit['asama_adi']?.toString() ?? '-'),
              _miniPlanBilgi('Adet', '${_planlananAdet(kayit)} adet'),
              _miniPlanBilgi(
                  'Başlangıç', _formatDate(kayit['uretim_baslangic_tarihi'])),
              _miniPlanBilgi(
                  'Bitiş', _formatDate(kayit['planlanan_bitis_tarihi'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniPlanBilgi(String baslik, String deger) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(
            deger,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _tableCellText(String text, {double width = 120, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
      ),
    );
  }

  Widget _firmaDurumChip(String durum) {
    final renk = _durumColor(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        durum,
        style: TextStyle(
          color: renk,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kayitlar = _filtreliKayitlar;
    final modelBazliKayitlar = _modelBazliKayitlar(kayitlar);
    final firmaBazliKayitlar = _firmaBazliKayitlar(kayitlar);

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
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.12),
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
                      OutlinedButton.icon(
                        onPressed: _showKapasiteYonetimiDialog,
                        icon: const Icon(Icons.business, size: 18),
                        label: const Text('Firma Kapasiteleri'),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message:
                            'Planı yapılmış modelleri üretim panellerindeki güncel durumlarına göre kontrol eder; plana uymayanları kırmızı çerçeveyle gösterir.',
                        child: OutlinedButton.icon(
                          onPressed: _kontrolModunuDegistir,
                          icon: Icon(
                            _kontrolModu
                                ? Icons.fact_check
                                : Icons.fact_check_outlined,
                            size: 18,
                          ),
                          label: const Text('Kontrol'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kontrolModu
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF2563EB),
                            side: BorderSide(
                              color: _kontrolModu
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF93C5FD),
                            ),
                          ),
                        ),
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
                  padding: const EdgeInsets.all(8),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        icon: Icon(Icons.view_list_outlined),
                        label: Text('Model Planları'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(Icons.business_outlined),
                        label: Text('Firma Planları'),
                      ),
                    ],
                    selected: {_aktifSekme},
                    onSelectionChanged: (value) {
                      setState(() => _aktifSekme = value.first);
                    },
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
                      if (_aktifSekme == 1) ...[
                        OutlinedButton.icon(
                          onPressed: firmaBazliKayitlar.isEmpty
                              ? null
                              : () => _firmaPlanlariniExcelAktar(
                                    firmaBazliKayitlar,
                                  ),
                          icon: const Icon(Icons.file_download_outlined,
                              size: 18),
                          label: const Text('Excel'),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        _aktifSekme == 0
                            ? '${modelBazliKayitlar.length} model planı'
                            : '${firmaBazliKayitlar.length} firma planı',
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
                            Icon(Icons.event_note,
                                size: 46, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Henüz üretim planı oluşturulmamış'),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _aktifSekme == 0
                      ? _buildTable(modelBazliKayitlar)
                      : _buildFirmaPlanlari(firmaBazliKayitlar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
