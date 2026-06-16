import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/models/rapor_filtresi.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class GelismisRaporServisleri {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  static String _modelRengi(Map<String, dynamic> model) {
    for (final key in ['renk', 'renk_kombinasyonu']) {
      final value = model[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final itemNo = model['item_no']?.toString().trim();
    if (itemNo == null || itemNo.isEmpty) return '';

    final parts = itemNo
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length < 2) return '';

    final suffix = parts.last.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]'), '');
    if (suffix.length < 2 ||
        suffix.length > 10 ||
        RegExp(r'^\d+$').hasMatch(suffix)) {
      return '';
    }

    return _renkKodunuGenislet(suffix);
  }

  static String _renkKodunuGenislet(String kod) {
    final normalized = kod
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');

    const renkKodlari = {
      'KAH': 'KAHVE',
      'KHV': 'KAHVE',
      'BRD': 'BORDO',
      'LAC': 'LACİVERT',
      'LACI': 'LACİVERT',
      'EKR': 'EKRU',
      'VIZ': 'VİZON',
      'BEJ': 'BEJ',
      'SYH': 'SİYAH',
      'SIY': 'SİYAH',
      'BEY': 'BEYAZ',
      'MAV': 'MAVİ',
      'MVI': 'MAVİ',
      'YES': 'YEŞİL',
      'YSL': 'YEŞİL',
      'KIR': 'KIRMIZI',
      'KRM': 'KIRMIZI',
      'GRI': 'GRİ',
      'GR': 'GRİ',
      'MOR': 'MOR',
      'PEM': 'PEMBE',
      'PUD': 'PUDRA',
      'SRT': 'SARI',
    };

    return renkKodlari[normalized] ?? kod.toUpperCase();
  }

  static double _doubleDeger(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  static int _intDeger(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _hedefBrutKarMarji(double hedefKarOrani) {
    if (hedefKarOrani <= -100) return 0;
    return (hedefKarOrani / (100 + hedefKarOrani)) * 100;
  }

  // ==============================================
  // PERSONEL VERİMLİLİK ANALİZİ
  // ==============================================

  /// Personel verimlilik ve performans analizi
  static Future<Map<String, dynamic>> getPersonelVerimlilikAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      // Personel listesini getir
      final personelQuery = _supabase
          .from(DbTables.personel)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('aktif', true);
      final personeller = await personelQuery;

      final int toplamPersonel = personeller.length;
      final int aktifPersonel =
          personeller.where((p) => p['aktif'] == true).length;
      final Map<String, int> departmanDagilimi = {};
      final Map<String, int> pozisyonDagilimi = {};
      final List<Map<String, dynamic>> personelPerformanslari = [];
      double toplamMesaiSaati = 0;

      for (var personel in personeller) {
        final departman = personel['departman']?.toString() ?? 'Belirtilmemiş';
        final pozisyon = personel['pozisyon']?.toString() ?? 'Belirtilmemiş';

        departmanDagilimi[departman] = (departmanDagilimi[departman] ?? 0) + 1;
        pozisyonDagilimi[pozisyon] = (pozisyonDagilimi[pozisyon] ?? 0) + 1;
      }

      // Mesai verilerini getir
      try {
        var mesaiQuery = _supabase
            .from(DbTables.mesaiKayitlari)
            .select('*')
            .eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          mesaiQuery = mesaiQuery.gte(
              'tarih', baslangicTarihi.toIso8601String().split('T')[0]);
        }
        if (bitisTarihi != null) {
          mesaiQuery = mesaiQuery.lte(
              'tarih', bitisTarihi.toIso8601String().split('T')[0]);
        }
        final mesailer = await mesaiQuery;

        for (var mesai in mesailer) {
          final saat =
              ((mesai['mesai_saati'] ?? mesai['toplam_saat'] ?? 0) as num)
                  .toDouble();
          toplamMesaiSaati += saat;
        }
      } catch (e) {
        AppLogger.debug('Veri isleme hatasi: $e');
      }

      // İzin verilerini getir
      int toplamIzinGunu = 0;
      int kullanilanIzin = 0;
      try {
        var izinQuery = _supabase
            .from(DbTables.izinKayitlari)
            .select('*')
            .eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          izinQuery = izinQuery.gte('baslangic_tarihi',
              baslangicTarihi.toIso8601String().split('T')[0]);
        }
        if (bitisTarihi != null) {
          izinQuery = izinQuery.lte(
              'bitis_tarihi', bitisTarihi.toIso8601String().split('T')[0]);
        }
        final izinler = await izinQuery;
        kullanilanIzin = izinler.length;
        for (var izin in izinler) {
          final gun = ((izin['gun_sayisi'] ?? 1) as num).toInt();
          toplamIzinGunu += gun;
        }
      } catch (e) {
        AppLogger.debug('Veri isleme hatasi: $e');
      }

      // Departman bazlı sıralama
      final siraliDepartmanlar = departmanDagilimi.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'toplamPersonel': toplamPersonel,
        'aktifPersonel': aktifPersonel,
        'departmanDagilimi': Map.fromEntries(siraliDepartmanlar),
        'pozisyonDagilimi': pozisyonDagilimi,
        'toplamMesaiSaati': toplamMesaiSaati,
        'ortalamaMesaiSaati':
            toplamPersonel > 0 ? toplamMesaiSaati / toplamPersonel : 0,
        'toplamIzinGunu': toplamIzinGunu,
        'kullanilanIzin': kullanilanIzin,
        'personelPerformanslari': personelPerformanslari,
      };
    } catch (e) {
      return {
        'toplamPersonel': 0,
        'aktifPersonel': 0,
        'departmanDagilimi': <String, int>{},
        'pozisyonDagilimi': <String, int>{},
        'toplamMesaiSaati': 0.0,
        'ortalamaMesaiSaati': 0.0,
        'toplamIzinGunu': 0,
        'kullanilanIzin': 0,
        'personelPerformanslari': <Map<String, dynamic>>[],
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // AYLIK TREND ANALİZİ
  // ==============================================

  /// Aylık üretim ve finansal trend analizi
  static Future<Map<String, dynamic>> getAylikTrendAnalizi({
    int aySayisi = 12,
  }) async {
    try {
      final now = DateTime.now();
      final baslangic = DateTime(now.year, now.month - aySayisi + 1, 1);

      // Modelleri getir
      final modeller = await _supabase
          .from(DbTables.trikoTakip)
          .select(
              'toplam_adet, adet, yuklenen_adet, pesin_fiyat, iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat, ilik_dugme_fiyat, aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, created_at')
          .eq('firma_id', _firmaId)
          .gte('created_at', baslangic.toIso8601String());

      // Aylık bazda grupla
      final Map<String, Map<String, dynamic>> aylikVeriler = {};
      final ayIsimleri = [
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara'
      ];

      for (var model in modeller) {
        if (model['created_at'] == null) continue;
        try {
          final tarih = DateTime.parse(model['created_at']);
          final ayKey =
              '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}';
          final ayLabel = '${ayIsimleri[tarih.month - 1]} ${tarih.year}';

          aylikVeriler.putIfAbsent(
              ayKey,
              () => {
                    'ayLabel': ayLabel,
                    'siparisAdedi': 0,
                    'toplamAdet': 0,
                    'yuklenenAdet': 0,
                    'toplamGelir': 0.0,
                    'toplamMaliyet': 0.0,
                    'modelSayisi': 0,
                  });

          final adet =
              ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
          final yuklenenAdet = ((model['yuklenen_adet'] ?? 0) as num).toInt();
          final fiyat = ((model['pesin_fiyat'] ?? 0) as num).toDouble();
          final iplik = ((model['iplik_maliyeti'] ?? 0) as num).toDouble();
          final orgu = ((model['orgu_fiyat'] ?? 0) as num).toDouble();
          final dikim = ((model['dikim_fiyat'] ?? 0) as num).toDouble();
          final utu = ((model['utu_fiyat'] ?? 0) as num).toDouble();
          final yikama = ((model['yikama_fiyat'] ?? 0) as num).toDouble();
          final ilikDugme =
              ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
          final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelAksesuar =
              ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelGider =
              ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
          final birimMaliyet = iplik +
              orgu +
              dikim +
              utu +
              yikama +
              ilikDugme +
              aksesuar +
              genelAksesuar +
              genelGider;

          aylikVeriler[ayKey]!['modelSayisi'] =
              (aylikVeriler[ayKey]!['modelSayisi'] as int) + 1;
          aylikVeriler[ayKey]!['toplamAdet'] =
              (aylikVeriler[ayKey]!['toplamAdet'] as int) + adet;
          aylikVeriler[ayKey]!['yuklenenAdet'] =
              (aylikVeriler[ayKey]!['yuklenenAdet'] as int) + yuklenenAdet;
          // Gelir ve maliyet sadece yüklenen adet üzerinden hesaplanır
          aylikVeriler[ayKey]!['toplamGelir'] =
              (aylikVeriler[ayKey]!['toplamGelir'] as double) +
                  (yuklenenAdet > 0 ? fiyat * yuklenenAdet : 0.0);
          aylikVeriler[ayKey]!['toplamMaliyet'] =
              (aylikVeriler[ayKey]!['toplamMaliyet'] as double) +
                  (yuklenenAdet > 0 ? birimMaliyet * yuklenenAdet : 0.0);
        } catch (e) {
          AppLogger.debug('Veri isleme hatasi: $e');
        }
      }

      // Kronolojik sırala
      final sirali = aylikVeriler.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Kar hesapla
      for (var entry in sirali) {
        final gelir = entry.value['toplamGelir'] as double;
        final maliyet = entry.value['toplamMaliyet'] as double;
        entry.value['kar'] = gelir - maliyet;
        entry.value['karMarji'] =
            gelir > 0 ? ((gelir - maliyet) / gelir) * 100 : 0.0;
      }

      return {
        'aylikVeriler': Map.fromEntries(sirali),
        'toplamAy': sirali.length,
      };
    } catch (e) {
      return {
        'aylikVeriler': <String, Map<String, dynamic>>{},
        'toplamAy': 0,
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // MALİYET VE KÂR/ZARAR ANALİZİ
  // ==============================================

  /// Model bazlı maliyet analizi
  static Future<Map<String, dynamic>> getModelMaliyetAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    RaporFiltresi? filtre,
  }) async {
    try {
      // Modelleri getir - gerçek veritabanı sütunları
      var query = _supabase.from(DbTables.trikoTakip).select('''
        id, marka, item_no, renk, renk_kombinasyonu, adet, toplam_adet, yuklenen_adet, created_at, termin_tarihi,
        iplik_maliyeti, iplik_kg_fiyati, orgu_fiyat, dikim_fiyat, 
        utu_fiyat, yikama_fiyat, ilik_dugme_fiyat, aksesuar_fiyat,
        genel_aksesuar_fiyat, genel_gider_fiyat, fermuar_fiyat, kar_marji, pesin_fiyat
      ''').eq('firma_id', _firmaId);

      if (baslangicTarihi != null) {
        query = query.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('created_at', bitisTarihi.toIso8601String());
      }
      if (filtre?.marka != null) {
        query = query.eq('marka', filtre!.marka!);
      }
      if (filtre?.model != null) {
        query = query.eq('item_no', filtre!.model!);
      }
      if (filtre?.yil != null) {
        query = query
            .gte('created_at', DateTime(filtre!.yil!, 1, 1).toIso8601String())
            .lt('created_at',
                DateTime(filtre.yil! + 1, 1, 1).toIso8601String());
      }

      final modeller = await query;
      final modelIds = modeller
          .map((model) => model['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
      final Map<String, Map<String, dynamic>> ozetByModelId = {};
      if (modelIds.isNotEmpty) {
        final ozetler = await _supabase
            .from(DbTables.modelKarlilikOzetleri)
            .select('*')
            .eq('firma_id', _firmaId)
            .inFilter('model_id', modelIds);
        for (final ozet in ozetler) {
          final modelId = ozet['model_id']?.toString();
          if (modelId != null && modelId.isNotEmpty) {
            ozetByModelId[modelId] = Map<String, dynamic>.from(ozet);
          }
        }
      }

      double toplamMaliyet = 0;
      double toplamPlanMaliyet = 0;
      double toplamIplikMaliyeti = 0;
      double toplamIscilikMaliyeti = 0;
      double toplamAksesuarMaliyeti = 0;
      double toplamGenelGider = 0;
      double toplamSatisFiyati = 0;
      int toplamAdet = 0;
      int toplamTamamlananAdet = 0;
      int toplamFireAdedi = 0;
      int sqlOzetliModelSayisi = 0;
      final Map<String, int> durumDagilimi = {};

      final List<Map<String, dynamic>> modelMaliyetleri = [];

      for (var model in modeller) {
        final adet =
            ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
        final yuklenenAdet = ((model['yuklenen_adet'] ?? 0) as num).toInt();

        // İplik maliyeti
        final iplik = ((model['iplik_maliyeti'] ?? 0) as num).toDouble();

        // İşçilik maliyetleri (örgü, dikim, ütü, yıkama, ilik düğme)
        final orgu = ((model['orgu_fiyat'] ?? 0) as num).toDouble();
        final dikim = ((model['dikim_fiyat'] ?? 0) as num).toDouble();
        final utu = ((model['utu_fiyat'] ?? 0) as num).toDouble();
        final yikama = ((model['yikama_fiyat'] ?? 0) as num).toDouble();
        final ilikDugme = ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
        final iscilikToplam = orgu + dikim + utu + yikama + ilikDugme;

        // Aksesuar maliyetleri
        final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
        final genelAksesuar =
            ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
        final aksesuarToplam = aksesuar + genelAksesuar;

        // Genel gider
        final genelGider =
            ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();

        // Satış fiyatı (peşin fiyat)
        final satis = ((model['pesin_fiyat'] ?? 0) as num).toDouble();

        // Birim maliyet hesapla
        final birimMaliyet =
            iplik + iscilikToplam + aksesuarToplam + genelGider;

        // Sadece yüklenen adet üzerinden hesapla - yükleme yoksa satış/maliyet yok
        final hesapAdet = yuklenenAdet > 0 ? yuklenenAdet : 0;
        final toplamModelMaliyet = birimMaliyet * hesapAdet;
        final toplamModelSatis = satis * hesapAdet;
        final kar = toplamModelSatis - toplamModelMaliyet;
        final karMarji =
            toplamModelSatis > 0 ? (kar / toplamModelSatis) * 100 : 0;

        toplamMaliyet += toplamModelMaliyet;
        toplamIplikMaliyeti += iplik * hesapAdet;
        toplamIscilikMaliyeti += iscilikToplam * hesapAdet;
        toplamAksesuarMaliyeti += aksesuarToplam * hesapAdet;
        toplamGenelGider += genelGider * hesapAdet;
        toplamSatisFiyati += toplamModelSatis;
        toplamAdet += adet;

        modelMaliyetleri.add({
          'id': model['id'],
          'marka': model['marka'] ?? '',
          'itemNo': model['item_no'] ?? '',
          'renk': _modelRengi(model),
          'adet': adet,
          'yuklenenAdet': yuklenenAdet,
          'iplikMaliyeti': iplik,
          'aksesuarMaliyeti': aksesuarToplam,
          'iscilikMaliyeti': iscilikToplam,
          'genelGider': genelGider,
          'birimMaliyet': birimMaliyet,
          'toplamMaliyet': toplamModelMaliyet,
          'satisFiyati': satis,
          'toplamSatis': toplamModelSatis,
          'kar': kar,
          'karMarji': karMarji,
        });
      }

      // En karlı ve en az karlı modeller
      if (ozetByModelId.isNotEmpty) {
        toplamMaliyet = 0;
        toplamPlanMaliyet = 0;
        toplamIplikMaliyeti = 0;
        toplamIscilikMaliyeti = 0;
        toplamAksesuarMaliyeti = 0;
        toplamGenelGider = 0;
        toplamSatisFiyati = 0;
        toplamAdet = 0;
        toplamTamamlananAdet = 0;
        toplamFireAdedi = 0;
        sqlOzetliModelSayisi = 0;
        durumDagilimi.clear();
        modelMaliyetleri.clear();

        for (final model in modeller) {
          final modelId = model['id']?.toString();
          final dbOzet = modelId == null ? null : ozetByModelId[modelId];
          final adet = dbOzet == null
              ? _intDeger(model['toplam_adet'] ?? model['adet'])
              : _intDeger(dbOzet['siparis_adedi']);
          final tamamlananAdet = dbOzet == null
              ? _intDeger(model['yuklenen_adet'])
              : _intDeger(dbOzet['tamamlanan_adet']);
          final fireAdedi =
              dbOzet == null ? 0 : _intDeger(dbOzet['fire_adedi']);
          final iplik = _doubleDeger(model['iplik_maliyeti']);
          final orgu = _doubleDeger(model['orgu_fiyat']);
          final dikim = _doubleDeger(model['dikim_fiyat']);
          final utu = _doubleDeger(model['utu_fiyat']);
          final yikama = _doubleDeger(model['yikama_fiyat']);
          final ilikDugme = _doubleDeger(model['ilik_dugme_fiyat']);
          final iscilikToplam = orgu + dikim + utu + yikama + ilikDugme;
          final aksesuar = _doubleDeger(model['aksesuar_fiyat']);
          final genelAksesuar = _doubleDeger(model['genel_aksesuar_fiyat']);
          final fermuar = _doubleDeger(model['fermuar_fiyat']);
          final aksesuarToplam = aksesuar + genelAksesuar + fermuar;
          final genelGider = _doubleDeger(model['genel_gider_fiyat']);
          final planBirimMaliyet =
              iplik + iscilikToplam + aksesuarToplam + genelGider;
          final satis = dbOzet == null
              ? _doubleDeger(model['pesin_fiyat'])
              : _doubleDeger(dbOzet['satis_birim_fiyati']);
          final hesapAdet = dbOzet == null
              ? (tamamlananAdet > 0 ? tamamlananAdet : 0)
              : (tamamlananAdet > 0 ? tamamlananAdet : adet);
          final planToplamMaliyet = dbOzet == null
              ? planBirimMaliyet * hesapAdet
              : _doubleDeger(dbOzet['plan_toplam_maliyet']);
          final gercekBirimMaliyet = dbOzet == null
              ? planBirimMaliyet
              : _doubleDeger(dbOzet['gercek_birim_maliyet']);
          final toplamModelMaliyet = dbOzet == null
              ? planBirimMaliyet * hesapAdet
              : _doubleDeger(dbOzet['gercek_toplam_maliyet']);
          final toplamModelSatis = dbOzet == null
              ? satis * hesapAdet
              : _doubleDeger(dbOzet['satis_geliri']);
          final kar = dbOzet == null
              ? toplamModelSatis - toplamModelMaliyet
              : _doubleDeger(dbOzet['brut_kar']);
          final karMarji = dbOzet == null
              ? (toplamModelSatis > 0 ? (kar / toplamModelSatis) * 100 : 0)
              : _doubleDeger(dbOzet['brut_kar_marji']);
          final hedefKarOrani = _doubleDeger(model['kar_marji']);
          final hedefBrutKarMarji = _hedefBrutKarMarji(hedefKarOrani);
          final karOrani =
              toplamModelMaliyet > 0 ? (kar / toplamModelMaliyet) * 100 : 0.0;
          final maliyetSapmasi =
              dbOzet == null ? 0.0 : _doubleDeger(dbOzet['maliyet_sapmasi']);
          final maliyetSapmaOrani = dbOzet == null
              ? 0.0
              : _doubleDeger(dbOzet['maliyet_sapma_orani']);
          final fireOrani =
              dbOzet == null ? 0.0 : _doubleDeger(dbOzet['fire_orani']);
          final durum = satis <= 0
              ? 'fiyat_eksik'
              : (kar < 0
                  ? 'zarar_riski'
                  : (hedefKarOrani > 0 && karOrani + 0.05 < hedefKarOrani
                      ? 'hedef_alti'
                      : (dbOzet == null ? 'ekran_hesabi' : 'hedefte')));

          toplamMaliyet += toplamModelMaliyet;
          toplamPlanMaliyet += planToplamMaliyet;
          final dagilimBaz = toplamModelMaliyet > 0
              ? toplamModelMaliyet
              : planBirimMaliyet * hesapAdet;
          if (planBirimMaliyet > 0 && dagilimBaz > 0) {
            toplamIplikMaliyeti += dagilimBaz * (iplik / planBirimMaliyet);
            toplamIscilikMaliyeti +=
                dagilimBaz * (iscilikToplam / planBirimMaliyet);
            toplamAksesuarMaliyeti +=
                dagilimBaz * (aksesuarToplam / planBirimMaliyet);
            toplamGenelGider += dagilimBaz * (genelGider / planBirimMaliyet);
          }
          toplamSatisFiyati += toplamModelSatis;
          toplamAdet += adet;
          toplamTamamlananAdet += tamamlananAdet;
          toplamFireAdedi += fireAdedi;
          if (dbOzet != null) sqlOzetliModelSayisi++;
          durumDagilimi[durum] = (durumDagilimi[durum] ?? 0) + 1;

          modelMaliyetleri.add({
            'id': model['id'],
            'marka': model['marka'] ?? '',
            'itemNo': model['item_no'] ?? '',
            'renk': _modelRengi(model),
            'adet': adet,
            'yuklenenAdet': tamamlananAdet,
            'tamamlananAdet': tamamlananAdet,
            'fireAdedi': fireAdedi,
            'iplikMaliyeti': iplik,
            'aksesuarMaliyeti': aksesuarToplam,
            'iscilikMaliyeti': iscilikToplam,
            'genelGider': genelGider,
            'planBirimMaliyet': planBirimMaliyet,
            'gercekBirimMaliyet': gercekBirimMaliyet,
            'birimMaliyet': gercekBirimMaliyet,
            'planToplamMaliyet': planToplamMaliyet,
            'toplamMaliyet': toplamModelMaliyet,
            'satisFiyati': satis,
            'toplamSatis': toplamModelSatis,
            'kar': kar,
            'karMarji': karMarji,
            'karOrani': karOrani,
            'hedefKarOrani': hedefKarOrani,
            'hedefBrutKarMarji': hedefBrutKarMarji,
            'maliyetSapmasi': maliyetSapmasi,
            'maliyetSapmaOrani': maliyetSapmaOrani,
            'fireOrani': fireOrani,
            'durum': durum,
            'veriKaynagi': dbOzet == null ? 'Ekran hesabı' : 'SQL özeti',
          });
        }
      }

      modelMaliyetleri
          .sort((a, b) => (b['kar'] as double).compareTo(a['kar'] as double));

      return {
        'modelMaliyetleri': modelMaliyetleri,
        'toplamMaliyet': toplamMaliyet,
        'toplamPlanMaliyet': toplamPlanMaliyet,
        'toplamIplikMaliyeti': toplamIplikMaliyeti,
        'toplamAksesuarMaliyeti': toplamAksesuarMaliyeti,
        'toplamIscilikMaliyeti': toplamIscilikMaliyeti,
        'toplamGenelGider': toplamGenelGider,
        'toplamSatisFiyati': toplamSatisFiyati,
        'toplamAdet': toplamAdet,
        'toplamTamamlananAdet': toplamTamamlananAdet,
        'toplamFireAdedi': toplamFireAdedi,
        'sqlOzetliModelSayisi': sqlOzetliModelSayisi,
        'durumDagilimi': durumDagilimi,
        'toplamKar': toplamSatisFiyati - toplamMaliyet,
        'ortalamaKarMarji': toplamSatisFiyati > 0
            ? ((toplamSatisFiyati - toplamMaliyet) / toplamSatisFiyati) * 100
            : 0,
        'maliyetSapmasi': toplamMaliyet - toplamPlanMaliyet,
        'maliyetSapmaOrani': toplamPlanMaliyet > 0
            ? ((toplamMaliyet - toplamPlanMaliyet) / toplamPlanMaliyet) * 100
            : 0,
        'fireOrani': toplamAdet > 0 ? (toplamFireAdedi / toplamAdet) * 100 : 0,
        'maliyetDagilimi': {
          'İplik': toplamIplikMaliyeti,
          'Aksesuar': toplamAksesuarMaliyeti,
          'İşçilik': toplamIscilikMaliyeti,
          'Genel Gider': toplamGenelGider,
        },
      };
    } catch (e) {
      return {
        'modelMaliyetleri': <Map<String, dynamic>>[],
        'toplamMaliyet': 0.0,
        'toplamPlanMaliyet': 0.0,
        'toplamIplikMaliyeti': 0.0,
        'toplamAksesuarMaliyeti': 0.0,
        'toplamIscilikMaliyeti': 0.0,
        'toplamGenelGider': 0.0,
        'toplamSatisFiyati': 0.0,
        'toplamAdet': 0,
        'toplamTamamlananAdet': 0,
        'toplamFireAdedi': 0,
        'sqlOzetliModelSayisi': 0,
        'durumDagilimi': <String, int>{},
        'toplamKar': 0.0,
        'ortalamaKarMarji': 0.0,
        'maliyetSapmasi': 0.0,
        'maliyetSapmaOrani': 0.0,
        'fireOrani': 0.0,
        'maliyetDagilimi': {
          'İplik': 0.0,
          'Aksesuar': 0.0,
          'İşçilik': 0.0,
          'Genel Gider': 0.0,
        },
        'hata': e.toString(),
      };
    }
  }

  /// Yükleme yapılan modeller için hedef/gerçek maliyet, kar/zarar ve fire finans analizi.
  static Future<Map<String, dynamic>> getYuklemeFinansAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    RaporFiltresi? filtre,
  }) async {
    try {
      final yuklemeQuery = _supabase
          .from(DbTables.yuklemeKayitlari)
          .select('id, model_id, adet, tarih, created_at')
          .eq('firma_id', _firmaId);

      final yuklemeler = await yuklemeQuery;
      final donemYuklemeByModel = <String, int>{};
      final donemYuklemeleriByModel = <String, List<Map<String, dynamic>>>{};
      for (final yukleme in yuklemeler) {
        if (!_yuklemeTarihAraliginda(yukleme, baslangicTarihi, bitisTarihi)) {
          continue;
        }
        final modelId = yukleme['model_id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        donemYuklemeByModel[modelId] =
            (donemYuklemeByModel[modelId] ?? 0) + _intDeger(yukleme['adet']);
        donemYuklemeleriByModel
            .putIfAbsent(modelId, () => [])
            .add(Map<String, dynamic>.from(yukleme));
      }

      var modelIds = donemYuklemeByModel.keys.toList();
      if (modelIds.isEmpty) return _bosYuklemeFinansAnalizi();

      var modelQuery = _supabase.from(DbTables.trikoTakip).select('''
        id, marka, item_no, renk, renk_kombinasyonu, adet, toplam_adet, yuklenen_adet, created_at, termin_tarihi,
        iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat, ilik_dugme_fiyat,
        aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, fermuar_fiyat, kar_marji, pesin_fiyat,
        vade_ay, vade_orani
      ''').eq('firma_id', _firmaId).inFilter('id', modelIds);

      if (filtre?.marka != null) {
        modelQuery = modelQuery.eq('marka', filtre!.marka!);
      }
      if (filtre?.model != null) {
        modelQuery = modelQuery.eq('item_no', filtre!.model!);
      }
      if (filtre?.modelId != null) {
        modelQuery = modelQuery.eq('id', filtre!.modelId!);
      }

      final modeller = await modelQuery;
      final modellerById = <String, Map<String, dynamic>>{};
      for (final model in modeller) {
        final modelId = model['id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        modellerById[modelId] = Map<String, dynamic>.from(model);
      }
      modelIds = modelIds.where(modellerById.containsKey).toList();
      if (modelIds.isEmpty) return _bosYuklemeFinansAnalizi();

      final tumYuklemeler = await _supabase
          .from(DbTables.yuklemeKayitlari)
          .select('model_id, adet')
          .eq('firma_id', _firmaId)
          .inFilter('model_id', modelIds);
      final toplamYuklemeByModel = <String, int>{};
      for (final yukleme in tumYuklemeler) {
        final modelId = yukleme['model_id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        toplamYuklemeByModel[modelId] =
            (toplamYuklemeByModel[modelId] ?? 0) + _intDeger(yukleme['adet']);
      }

      final ozetByModelId = <String, Map<String, dynamic>>{};
      final ozetler = await _supabase
          .from(DbTables.modelKarlilikOzetleri)
          .select('*')
          .eq('firma_id', _firmaId)
          .inFilter('model_id', modelIds);
      for (final ozet in ozetler) {
        final modelId = ozet['model_id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        ozetByModelId[modelId] = Map<String, dynamic>.from(ozet);
      }

      final planByModelId = <String, Map<String, dynamic>>{};
      final planlar = await _supabase
          .from(DbTables.modelMaliyetPlanlari)
          .select('*')
          .eq('firma_id', _firmaId)
          .inFilter('model_id', modelIds)
          .order('updated_at', ascending: false);
      for (final plan in planlar) {
        final modelId = plan['model_id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        final mevcut = planByModelId[modelId];
        if (mevcut == null || plan['durum'] == 'aktif') {
          planByModelId[modelId] = Map<String, dynamic>.from(plan);
        }
      }
      final planIds = planByModelId.values
          .map((plan) => plan['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
      final kalemlerByPlanId = <String, List<Map<String, dynamic>>>{};
      if (planIds.isNotEmpty) {
        final kalemler = await _supabase
            .from(DbTables.modelMaliyetKalemleri)
            .select('*')
            .eq('firma_id', _firmaId)
            .inFilter('plan_id', planIds)
            .order('sira_no', ascending: true)
            .order('created_at', ascending: true);
        for (final kalem in kalemler) {
          final planId = kalem['plan_id']?.toString();
          if (planId == null || planId.isEmpty) continue;
          kalemlerByPlanId
              .putIfAbsent(planId, () => [])
              .add(Map<String, dynamic>.from(kalem));
        }
      }

      final gerceklesenByModelId = <String, Map<String, Map<String, double>>>{};
      final gerceklesenler = await _supabase
          .from(DbTables.modelMaliyetGerceklesen)
          .select('model_id, kalem_tipi, miktar, toplam_tutar, fire_adedi')
          .eq('firma_id', _firmaId)
          .inFilter('model_id', modelIds);
      for (final kayit in gerceklesenler) {
        final modelId = kayit['model_id']?.toString();
        if (modelId == null || modelId.isEmpty) continue;
        final kalemTipi = kayit['kalem_tipi']?.toString().trim();
        final kod = kalemTipi == null || kalemTipi.isEmpty
            ? 'diger'
            : (kalemTipi == 'baski_nakis' ? 'nakis' : kalemTipi);
        final modelGerceklesen =
            gerceklesenByModelId.putIfAbsent(modelId, () => {});
        final hedef = modelGerceklesen.putIfAbsent(
          kod,
          () => {'tutar': 0, 'miktar': 0, 'fire': 0},
        );
        hedef['tutar'] =
            (hedef['tutar'] ?? 0) + _doubleDeger(kayit['toplam_tutar']);
        hedef['miktar'] =
            (hedef['miktar'] ?? 0) + _doubleDeger(kayit['miktar']);
        hedef['fire'] =
            (hedef['fire'] ?? 0) + _doubleDeger(kayit['fire_adedi']);
      }

      final fireByModelId = await _yuklemeFinansFireAdetleriGetir(modelIds);

      final operasyonelGiderler = await _operasyonelGiderleriGetir(
        baslangicTarihi: baslangicTarihi,
        bitisTarihi: bitisTarihi,
      );
      final toplamOperasyonelGider =
          _doubleDeger(operasyonelGiderler['toplam']);

      double toplamHedefMaliyet = 0;
      double toplamGercekMaliyet = 0;
      double toplamSatisGeliri = 0;
      double toplamKar = 0;
      double toplamBrutKar = 0;
      double toplamUretimMaliyeti = 0;
      double toplamFireMaliyeti = 0;
      double toplamKayipKazanc = 0;
      int toplamSiparisAdedi = 0;
      int toplamUretilenAdet = 0;
      int toplamDonemYuklenenAdet = 0;
      int toplamYuklenenAdet = 0;
      int toplamKalanAdet = 0;
      int toplamFireAdedi = 0;
      int zararModelSayisi = 0;
      int hedefAltiSayisi = 0;
      int fiyatEksikSayisi = 0;
      int maliyetEksikSayisi = 0;
      int hesaplanabilirModelSayisi = 0;
      final durumDagilimi = <String, int>{};
      final modelFinanslari = <Map<String, dynamic>>[];
      final markaAnalizi = <String, Map<String, dynamic>>{};
      final aylikAnaliz = <String, Map<String, dynamic>>{};
      final maliyetDagilimi = <String, double>{};
      final toplamDonemYuklenenReferans = donemYuklemeByModel.values.fold<int>(
        0,
        (sum, adet) => sum + adet,
      );

      for (final modelId in modelIds) {
        final model = modellerById[modelId]!;
        final ozet = ozetByModelId[modelId];
        final plan = planByModelId[modelId];
        final gerceklesen = gerceklesenByModelId[modelId];
        final siparisAdedi = _intDeger(model['toplam_adet'] ?? model['adet']);
        final donemYuklenenAdet = donemYuklemeByModel[modelId] ?? 0;
        final toplamModelYuklenen = toplamYuklemeByModel[modelId] ?? 0;
        final ozetTamamlanan = _intDeger(ozet?['tamamlanan_adet']);
        final uretilenAdet = ozetTamamlanan > toplamModelYuklenen
            ? ozetTamamlanan
            : toplamModelYuklenen;
        final kalanAdet =
            (siparisAdedi - toplamModelYuklenen).clamp(0, siparisAdedi);
        final planKalemleri = plan == null
            ? <Map<String, dynamic>>[]
            : kalemlerByPlanId[plan['id']?.toString()] ??
                <Map<String, dynamic>>[];
        final maliyetKalemleri = _fiyatlandirmaMaliyetKalemleri(
          model: model,
          planKalemleri: planKalemleri,
        );
        final gercekBirimliKalemler = _gercekBirimliMaliyetKalemleri(
          maliyetKalemleri: maliyetKalemleri,
          gerceklesenKalemleri: gerceklesen,
          fallbackAdet: ozetTamamlanan > 0 ? ozetTamamlanan : siparisAdedi,
        );
        final planBirimMaliyet = gercekBirimliKalemler.fold<double>(
          0,
          (sum, kalem) => sum + _doubleDeger(kalem['planBirim']),
        );
        final gercekBirimMaliyet = gercekBirimliKalemler.fold<double>(
          0,
          (sum, kalem) => sum + _doubleDeger(kalem['gercekBirim']),
        );
        final modelKarOrani = _doubleDeger(model['kar_marji']);
        final hedefKarOrani = modelKarOrani > 0
            ? modelKarOrani
            : _doubleDeger(plan?['hedef_kar_marji']);
        final satisBirimFiyati = _fiyatlandirmaSatisFiyati(
          model,
          planBirimMaliyet,
          hedefKarOrani,
        );
        final fireAdedi = [
          fireByModelId[modelId] ?? 0,
          _intDeger(ozet?['fire_adedi']),
        ].reduce((a, b) => a >= b ? a : b);
        final double? hedefMaliyet =
            planBirimMaliyet > 0 ? planBirimMaliyet * donemYuklenenAdet : null;
        final double? gercekMaliyet = gercekBirimMaliyet > 0
            ? gercekBirimMaliyet * donemYuklenenAdet
            : null;
        final double? satisGeliri =
            satisBirimFiyati > 0 ? satisBirimFiyati * donemYuklenenAdet : null;
        final double? maliyetSapmasi =
            gercekMaliyet == null || hedefMaliyet == null
                ? null
                : gercekMaliyet - hedefMaliyet;
        final double? maliyetSapmaOrani =
            maliyetSapmasi == null || hedefMaliyet == null || hedefMaliyet <= 0
                ? null
                : (maliyetSapmasi / hedefMaliyet) * 100;
        final fireBirimMaliyeti = gercekBirimMaliyet > 0
            ? gercekBirimMaliyet
            : (planBirimMaliyet > 0 ? planBirimMaliyet : null);
        final double? fireMaliyeti =
            fireBirimMaliyeti == null ? null : fireBirimMaliyeti * fireAdedi;
        final double operasyonelGiderPayi = toplamDonemYuklenenReferans <= 0
            ? 0
            : toplamOperasyonelGider *
                (donemYuklenenAdet / toplamDonemYuklenenReferans);
        final double? uretimMaliyeti = gercekMaliyet ?? hedefMaliyet;
        final double genelToplamMaliyet =
            (uretimMaliyeti ?? 0) + operasyonelGiderPayi + (fireMaliyeti ?? 0);
        final double? brutKar = satisGeliri == null || uretimMaliyeti == null
            ? null
            : satisGeliri - uretimMaliyeti - (fireMaliyeti ?? 0);
        final double? netKar =
            satisGeliri == null ? null : satisGeliri - genelToplamMaliyet;
        final double? netKarMarji =
            netKar == null || satisGeliri == null || satisGeliri <= 0
                ? null
                : (netKar / satisGeliri) * 100;
        final double? gercekKarOrani = netKar == null || genelToplamMaliyet <= 0
            ? null
            : (netKar / genelToplamMaliyet) * 100;
        final double? birimKar = netKar == null || donemYuklenenAdet <= 0
            ? null
            : netKar / donemYuklenenAdet;
        final double kayipKazanc = satisBirimFiyati * kalanAdet;
        final fireOrani =
            siparisAdedi > 0 ? (fireAdedi / siparisAdedi) * 100 : 0.0;
        final durum = uretimMaliyeti == null
            ? 'maliyet_eksik'
            : (satisBirimFiyati <= 0
                ? 'fiyat_eksik'
                : (netKar != null && netKar < 0
                    ? 'zarar_riski'
                    : (hedefKarOrani > 0 &&
                            gercekKarOrani != null &&
                            gercekKarOrani + 0.05 < hedefKarOrani
                        ? 'hedef_alti'
                        : 'hedefte')));

        if (hedefMaliyet != null) toplamHedefMaliyet += hedefMaliyet;
        if (gercekMaliyet != null) toplamGercekMaliyet += gercekMaliyet;
        if (satisGeliri != null) toplamSatisGeliri += satisGeliri;
        if (brutKar != null) toplamBrutKar += brutKar;
        if (netKar != null) toplamKar += netKar;
        if (fireMaliyeti != null) toplamFireMaliyeti += fireMaliyeti;
        if (uretimMaliyeti != null) toplamUretimMaliyeti += uretimMaliyeti;
        toplamKayipKazanc += kayipKazanc;
        toplamSiparisAdedi += siparisAdedi;
        toplamUretilenAdet += uretilenAdet;
        toplamDonemYuklenenAdet += donemYuklenenAdet;
        toplamYuklenenAdet += toplamModelYuklenen;
        toplamKalanAdet += kalanAdet;
        toplamFireAdedi += fireAdedi;
        if (durum == 'zarar_riski') zararModelSayisi++;
        if (durum == 'hedef_alti') hedefAltiSayisi++;
        if (durum == 'fiyat_eksik') fiyatEksikSayisi++;
        if (durum == 'maliyet_eksik') maliyetEksikSayisi++;
        if (netKar != null) hesaplanabilirModelSayisi++;
        durumDagilimi[durum] = (durumDagilimi[durum] ?? 0) + 1;

        for (final kalem in gercekBirimliKalemler) {
          final ad = kalem['ad']?.toString() ?? 'Diğer';
          maliyetDagilimi[ad] = (maliyetDagilimi[ad] ?? 0) +
              _doubleDeger(kalem['gercekBirim']) * donemYuklenenAdet;
        }
        if (fireMaliyeti != null) {
          maliyetDagilimi['Fire Maliyeti'] =
              (maliyetDagilimi['Fire Maliyeti'] ?? 0) + fireMaliyeti;
        }
        if (operasyonelGiderPayi > 0) {
          maliyetDagilimi['Operasyonel Gider'] =
              (maliyetDagilimi['Operasyonel Gider'] ?? 0) +
                  operasyonelGiderPayi;
        }

        final marka = model['marka']?.toString().trim().isNotEmpty == true
            ? model['marka'].toString()
            : 'Diğer';
        final markaSatiri = markaAnalizi.putIfAbsent(
          marka,
          () => {
            'marka': marka,
            'modelSayisi': 0,
            'siparisAdedi': 0,
            'ciro': 0.0,
            'maliyet': 0.0,
            'kar': 0.0,
          },
        );
        markaSatiri['modelSayisi'] = _intDeger(markaSatiri['modelSayisi']) + 1;
        markaSatiri['siparisAdedi'] =
            _intDeger(markaSatiri['siparisAdedi']) + siparisAdedi;
        markaSatiri['ciro'] =
            _doubleDeger(markaSatiri['ciro']) + (satisGeliri ?? 0);
        markaSatiri['maliyet'] =
            _doubleDeger(markaSatiri['maliyet']) + genelToplamMaliyet;
        markaSatiri['kar'] = _doubleDeger(markaSatiri['kar']) + (netKar ?? 0);

        final modelDonemYuklemeleri =
            donemYuklemeleriByModel[modelId] ?? const <Map<String, dynamic>>[];
        for (final yukleme in modelDonemYuklemeleri) {
          final ayKey = _ayAnahtari(yukleme['tarih'] ?? yukleme['created_at']);
          if (ayKey == null) continue;
          final adet = _intDeger(yukleme['adet']);
          final oran = donemYuklenenAdet <= 0 ? 0.0 : adet / donemYuklenenAdet;
          final ay = aylikAnaliz.putIfAbsent(
            ayKey,
            () => {
              'ay': ayKey,
              'ciro': 0.0,
              'kar': 0.0,
              'uretimAdedi': 0,
              'yuklemeAdedi': 0,
              'fireAdedi': 0,
            },
          );
          ay['ciro'] = _doubleDeger(ay['ciro']) + (satisBirimFiyati * adet);
          ay['kar'] = _doubleDeger(ay['kar']) + ((netKar ?? 0) * oran);
          ay['uretimAdedi'] = _intDeger(ay['uretimAdedi']) + adet;
          ay['yuklemeAdedi'] = _intDeger(ay['yuklemeAdedi']) + adet;
          ay['fireAdedi'] =
              _intDeger(ay['fireAdedi']) + (fireAdedi * oran).round();
        }

        modelFinanslari.add({
          'id': modelId,
          'marka': model['marka'] ?? '',
          'itemNo': model['item_no'] ?? '',
          'renk': _modelRengi(model),
          'siparisAdedi': siparisAdedi,
          'uretilenAdet': uretilenAdet,
          'donemYuklenenAdet': donemYuklenenAdet,
          'toplamYuklenenAdet': toplamModelYuklenen,
          'kalanAdet': kalanAdet,
          'planBirimMaliyet': planBirimMaliyet,
          'gercekBirimMaliyet': gercekBirimMaliyet,
          'satisBirimFiyati': satisBirimFiyati,
          'hedefMaliyet': hedefMaliyet,
          'gercekMaliyet': gercekMaliyet,
          'maliyetSapmasi': maliyetSapmasi,
          'maliyetSapmaOrani': maliyetSapmaOrani,
          'satisGeliri': satisGeliri,
          'toplamUretimMaliyeti': uretimMaliyeti,
          'toplamOperasyonelMaliyet': operasyonelGiderPayi,
          'genelToplamMaliyet': genelToplamMaliyet,
          'brutKar': brutKar,
          'netKar': netKar,
          'kar': netKar,
          'karMarji': gercekKarOrani,
          'gercekKarOrani': gercekKarOrani,
          'netKarMarji': netKarMarji,
          'birimKar': birimKar,
          'kayipKazanc': kayipKazanc,
          'fireAdedi': fireAdedi,
          'fireBirimMaliyeti': fireBirimMaliyeti,
          'fireMaliyeti': fireMaliyeti,
          'fireOrani': fireOrani,
          'hedefKarMarji': hedefKarOrani,
          'hedefKarOrani': hedefKarOrani,
          'durum': durum,
          'maliyetVerisiVar': gercekBirimMaliyet > 0,
          'satisFiyatiVar': satisBirimFiyati > 0,
          'maliyetKalemleri': gercekBirimliKalemler,
          'fiyatlandirmaKaynak': planKalemleri.isNotEmpty
              ? 'Aktif maliyet planı'
              : 'Model fiyatlandırma',
        });
      }

      modelFinanslari.sort(
          (a, b) => ((a['kar'] ?? 0) as num).compareTo((b['kar'] ?? 0) as num));
      for (final marka in markaAnalizi.values) {
        final ciro = _doubleDeger(marka['ciro']);
        final maliyet = _doubleDeger(marka['maliyet']);
        final kar = _doubleDeger(marka['kar']);
        marka['karMarji'] = maliyet > 0 ? (kar / maliyet) * 100 : 0.0;
        marka['netKarMarji'] = ciro > 0 ? (kar / ciro) * 100 : 0.0;
      }
      final enZararliModeller = modelFinanslari
          .where((model) => _doubleDeger(model['netKar']) < 0)
          .take(10)
          .toList();
      final enKarliModeller = modelFinanslari.reversed
          .where((model) => _doubleDeger(model['netKar']) > 0)
          .take(10)
          .toList();
      final markaListesi = markaAnalizi.values.toList()
        ..sort(
            (a, b) => _doubleDeger(b['kar']).compareTo(_doubleDeger(a['kar'])));
      final aylikListesi = aylikAnaliz.values.toList()
        ..sort((a, b) =>
            (a['ay'] ?? '').toString().compareTo((b['ay'] ?? '').toString()));
      final maliyetDagilimiListesi = maliyetDagilimi.entries
          .map((entry) => {'ad': entry.key, 'tutar': entry.value})
          .where((entry) => _doubleDeger(entry['tutar']) > 0)
          .toList()
        ..sort((a, b) =>
            _doubleDeger(b['tutar']).compareTo(_doubleDeger(a['tutar'])));

      final toplamGenelToplamMaliyet =
          toplamUretimMaliyeti + toplamOperasyonelGider + toplamFireMaliyeti;

      return {
        'modelFinanslari': modelFinanslari,
        'durumDagilimi': durumDagilimi,
        'markaAnalizi': markaListesi,
        'aylikAnaliz': aylikListesi,
        'maliyetDagilimi': maliyetDagilimiListesi,
        'operasyonelGiderDagilimi':
            operasyonelGiderler['kategoriler'] ?? <Map<String, dynamic>>[],
        'enKarliModeller': enKarliModeller,
        'enZararliModeller': enZararliModeller,
        'toplamModel': modelFinanslari.length,
        'toplamSiparisAdedi': toplamSiparisAdedi,
        'toplamUretilenAdet': toplamUretilenAdet,
        'toplamDonemYuklenenAdet': toplamDonemYuklenenAdet,
        'toplamYuklenenAdet': toplamYuklenenAdet,
        'toplamKalanAdet': toplamKalanAdet,
        'toplamHedefMaliyet': toplamHedefMaliyet,
        'toplamGercekMaliyet': toplamGercekMaliyet,
        'toplamUretimMaliyeti': toplamUretimMaliyeti,
        'toplamOperasyonelGider': toplamOperasyonelGider,
        'genelToplamMaliyet': toplamGenelToplamMaliyet,
        'toplamSatisGeliri': toplamSatisGeliri,
        'toplamBrutKar': toplamBrutKar,
        'toplamNetKar': toplamKar,
        'toplamKar': toplamKar,
        'toplamKayipKazanc': toplamKayipKazanc,
        'ortalamaKarMarji': toplamGenelToplamMaliyet > 0
            ? (toplamKar / toplamGenelToplamMaliyet) * 100
            : 0.0,
        'ortalamaNetKarMarji':
            toplamSatisGeliri > 0 ? (toplamKar / toplamSatisGeliri) * 100 : 0.0,
        'maliyetSapmasi': toplamGercekMaliyet - toplamHedefMaliyet,
        'maliyetSapmaOrani': toplamHedefMaliyet > 0
            ? ((toplamGercekMaliyet - toplamHedefMaliyet) /
                    toplamHedefMaliyet) *
                100
            : 0.0,
        'toplamFireAdedi': toplamFireAdedi,
        'toplamFireMaliyeti': toplamFireMaliyeti,
        'fireOrani': toplamSiparisAdedi > 0
            ? (toplamFireAdedi / toplamSiparisAdedi) * 100
            : 0.0,
        'zararModelSayisi': zararModelSayisi,
        'hedefAltiSayisi': hedefAltiSayisi,
        'fiyatEksikSayisi': fiyatEksikSayisi,
        'maliyetEksikSayisi': maliyetEksikSayisi,
        'hesaplanabilirModelSayisi': hesaplanabilirModelSayisi,
      };
    } catch (e) {
      final bos = _bosYuklemeFinansAnalizi();
      bos['hata'] = e.toString();
      return bos;
    }
  }

  static Future<Map<String, dynamic>> _operasyonelGiderleriGetir({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    final kategoriler = <String, double>{};

    void ekle(String kategori, double tutar) {
      if (tutar <= 0) return;
      final temizKategori = kategori.trim().isEmpty ? 'Diğer' : kategori.trim();
      kategoriler[temizKategori] = (kategoriler[temizKategori] ?? 0) + tutar;
    }

    try {
      var hareketQuery = _supabase
          .from(DbTables.kasaBankaHareketleri)
          .select('*')
          .eq('firma_id', _firmaId);
      if (baslangicTarihi != null) {
        hareketQuery = hareketQuery.gte(
          'tarih',
          baslangicTarihi.toIso8601String().split('T').first,
        );
      }
      if (bitisTarihi != null) {
        hareketQuery = hareketQuery.lte(
          'tarih',
          bitisTarihi.toIso8601String().split('T').first,
        );
      }
      final hareketler = await hareketQuery;
      for (final hareket in hareketler) {
        final tip = hareket['islem_tipi']?.toString() ??
            hareket['hareket_tipi']?.toString() ??
            '';
        if (tip != 'gider' && tip != 'cikis' && tip != 'odeme') continue;
        ekle(
          hareket['kategori']?.toString() ??
              hareket['aciklama']?.toString() ??
              'Operasyonel Gider',
          _doubleDeger(hareket['tutar']),
        );
      }
    } catch (e) {
      AppLogger.debug('Kasa/banka operasyonel giderleri okunamadı: $e');
    }

    final liste = kategoriler.entries
        .map((entry) => {'ad': entry.key, 'tutar': entry.value})
        .toList()
      ..sort((a, b) =>
          _doubleDeger(b['tutar']).compareTo(_doubleDeger(a['tutar'])));

    return {
      'toplam': kategoriler.values.fold<double>(0, (sum, tutar) => sum + tutar),
      'kategoriler': liste,
    };
  }

  static String? _ayAnahtari(dynamic tarihDegeri) {
    if (tarihDegeri == null) return null;
    final tarih = DateTime.tryParse(tarihDegeri.toString());
    if (tarih == null) return null;
    return '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, int>> _yuklemeFinansFireAdetleriGetir(
    List<String> modelIds,
  ) async {
    if (modelIds.isEmpty) return {};

    final detayliFire = await _fireKayitlariAdetleriGetir(modelIds);
    final asamaFire = await _asamaAtamaFireAdetleriGetir(modelIds);
    final sonuc = <String, int>{};

    for (final modelId in modelIds) {
      final detayAdet = detayliFire[modelId] ?? 0;
      final asamaAdet = asamaFire[modelId] ?? 0;
      final adet = detayAdet >= asamaAdet ? detayAdet : asamaAdet;
      if (adet > 0) sonuc[modelId] = adet;
    }

    return sonuc;
  }

  static Future<Map<String, int>> _fireKayitlariAdetleriGetir(
    List<String> modelIds,
  ) async {
    Future<List<dynamic>> sorgula({required bool firmaFiltresi}) async {
      var query = _supabase
          .from(DbTables.fireKayitlari)
          .select('model_id, adet')
          .inFilter('model_id', modelIds);
      if (firmaFiltresi) {
        query = query.eq('firma_id', _firmaId);
      }
      return await query;
    }

    try {
      return _fireSatirlariniTopla(await sorgula(firmaFiltresi: true));
    } catch (e) {
      AppLogger.debug(
        'Fire kayıtları firma filtresiyle okunamadı, filtresiz deneniyor: $e',
      );
      try {
        return _fireSatirlariniTopla(await sorgula(firmaFiltresi: false));
      } catch (retryError) {
        AppLogger.debug(
          'Fire kayıtları yükleme finansına eklenemedi: $retryError',
        );
        return {};
      }
    }
  }

  static Future<Map<String, int>> _asamaAtamaFireAdetleriGetir(
    List<String> modelIds,
  ) async {
    const tablolar = [
      DbTables.dokumaAtamalari,
      DbTables.konfeksiyonAtamalari,
      DbTables.nakisAtamalari,
      DbTables.yikamaAtamalari,
      DbTables.ilikDugmeAtamalari,
      DbTables.utuAtamalari,
      DbTables.kaliteKontrolAtamalari,
      DbTables.paketlemeAtamalari,
    ];

    final sonuc = <String, int>{};
    for (final tablo in tablolar) {
      try {
        final satirlar = await _supabase
            .from(tablo)
            .select('model_id, fire_adet')
            .eq('firma_id', _firmaId)
            .inFilter('model_id', modelIds);
        for (final satir in satirlar) {
          final modelId = satir['model_id']?.toString();
          if (modelId == null || modelId.isEmpty) continue;
          final fireAdet = _intDeger(satir['fire_adet']);
          if (fireAdet <= 0) continue;
          sonuc[modelId] = (sonuc[modelId] ?? 0) + fireAdet;
        }
      } catch (e) {
        AppLogger.debug('$tablo fire adetleri okunamadı: $e');
      }
    }

    return sonuc;
  }

  static Map<String, int> _fireSatirlariniTopla(List<dynamic> satirlar) {
    final sonuc = <String, int>{};
    for (final satir in satirlar) {
      if (satir is! Map) continue;
      final modelId = satir['model_id']?.toString();
      if (modelId == null || modelId.isEmpty) continue;
      final adet = _intDeger(satir['adet']);
      if (adet <= 0) continue;
      sonuc[modelId] = (sonuc[modelId] ?? 0) + adet;
    }
    return sonuc;
  }

  static bool _yuklemeTarihAraliginda(
    Map<String, dynamic> yukleme,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  ) {
    if (baslangicTarihi == null && bitisTarihi == null) return true;
    final tarihDegeri = yukleme['tarih'] ?? yukleme['created_at'];
    if (tarihDegeri == null) return false;
    final tarih = DateTime.tryParse(tarihDegeri.toString());
    if (tarih == null) return false;
    if (baslangicTarihi != null) {
      final baslangic = DateTime(
        baslangicTarihi.year,
        baslangicTarihi.month,
        baslangicTarihi.day,
      );
      if (tarih.isBefore(baslangic)) return false;
    }
    if (bitisTarihi != null) {
      final bitis = DateTime(
        bitisTarihi.year,
        bitisTarihi.month,
        bitisTarihi.day,
        23,
        59,
        59,
        999,
      );
      if (tarih.isAfter(bitis)) return false;
    }
    return true;
  }

  static Map<String, dynamic> _bosYuklemeFinansAnalizi() {
    return {
      'modelFinanslari': <Map<String, dynamic>>[],
      'durumDagilimi': <String, int>{},
      'markaAnalizi': <Map<String, dynamic>>[],
      'aylikAnaliz': <Map<String, dynamic>>[],
      'maliyetDagilimi': <Map<String, dynamic>>[],
      'operasyonelGiderDagilimi': <Map<String, dynamic>>[],
      'enKarliModeller': <Map<String, dynamic>>[],
      'enZararliModeller': <Map<String, dynamic>>[],
      'toplamModel': 0,
      'toplamSiparisAdedi': 0,
      'toplamUretilenAdet': 0,
      'toplamDonemYuklenenAdet': 0,
      'toplamYuklenenAdet': 0,
      'toplamKalanAdet': 0,
      'toplamHedefMaliyet': 0.0,
      'toplamGercekMaliyet': 0.0,
      'toplamUretimMaliyeti': 0.0,
      'toplamOperasyonelGider': 0.0,
      'genelToplamMaliyet': 0.0,
      'toplamSatisGeliri': 0.0,
      'toplamBrutKar': 0.0,
      'toplamNetKar': 0.0,
      'toplamKar': 0.0,
      'toplamKayipKazanc': 0.0,
      'ortalamaKarMarji': 0.0,
      'ortalamaNetKarMarji': 0.0,
      'maliyetSapmasi': 0.0,
      'maliyetSapmaOrani': 0.0,
      'toplamFireAdedi': 0,
      'toplamFireMaliyeti': 0.0,
      'fireOrani': 0.0,
      'zararModelSayisi': 0,
      'hedefAltiSayisi': 0,
      'fiyatEksikSayisi': 0,
      'maliyetEksikSayisi': 0,
      'hesaplanabilirModelSayisi': 0,
    };
  }

  static List<Map<String, dynamic>> _fiyatlandirmaMaliyetKalemleri({
    required Map<String, dynamic> model,
    required List<Map<String, dynamic>> planKalemleri,
  }) {
    final kullanilabilirPlanKalemleri = planKalemleri
        .where((kalem) => kalem['kalem_tipi']?.toString() != 'aksesuar')
        .toList();
    if (kullanilabilirPlanKalemleri.isNotEmpty) {
      return kullanilabilirPlanKalemleri
          .map((kalem) {
            final planBirim = _doubleDeger(kalem['plan_birim_maliyet']);
            if (planBirim <= 0) return null;
            final ad = kalem['aciklama']?.toString().trim().isNotEmpty == true
                ? kalem['aciklama'].toString()
                : _maliyetKalemEtiketi(kalem['kalem_tipi']?.toString() ?? '');
            return {
              'kod': kalem['kalem_tipi']?.toString() ?? '',
              'ad': ad,
              'planBirim': planBirim,
              'gercekBirim': planBirim,
              'kaynak': kalem['kaynak']?.toString() ?? 'plan',
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    final kalemler = [
      _fiyatlandirmaKalemi('iplik', 'İplik Maliyeti', model['iplik_maliyeti']),
      _fiyatlandirmaKalemi(
          'genel_aksesuar', 'Genel Aksesuar', model['genel_aksesuar_fiyat']),
      _fiyatlandirmaKalemi('orgu', 'Örgü / Dokuma', model['orgu_fiyat']),
      _fiyatlandirmaKalemi('dikim', 'Dikim', model['dikim_fiyat']),
      _fiyatlandirmaKalemi('yikama', 'Yıkama', model['yikama_fiyat']),
      _fiyatlandirmaKalemi(
          'ilik_dugme', 'İlik Düğme', model['ilik_dugme_fiyat']),
      _fiyatlandirmaKalemi('fermuar', 'Fermuar', model['fermuar_fiyat']),
      _fiyatlandirmaKalemi('konfeksiyon', 'Konfeksiyon', 0),
      _fiyatlandirmaKalemi('utu', 'Ütü', model['utu_fiyat']),
      _fiyatlandirmaKalemi('nakis', 'Nakış / Baskı', model['aksesuar_fiyat']),
      _fiyatlandirmaKalemi('nakliye', 'Nakliye', 0),
      _fiyatlandirmaKalemi('numune', 'Numune', 0),
      _fiyatlandirmaKalemi(
          'genel_gider', 'Diğer Giderler', model['genel_gider_fiyat']),
    ].whereType<Map<String, dynamic>>().toList();

    return kalemler;
  }

  static Map<String, dynamic>? _fiyatlandirmaKalemi(
    String kod,
    String ad,
    dynamic value,
  ) {
    final tutar = _doubleDeger(value);
    return {
      'kod': kod,
      'ad': ad,
      'planBirim': tutar,
      'gercekBirim': tutar,
      'kaynak': 'model_fiyatlandirma',
    };
  }

  static double _fiyatlandirmaSatisFiyati(
    Map<String, dynamic> model,
    double planBirimMaliyet,
    double karMarji,
  ) {
    if (planBirimMaliyet <= 0) return 0;
    var satisFiyati = planBirimMaliyet * (1 + karMarji / 100);
    final vadeAy = _intDeger(model['vade_ay']);
    final vadeOrani = _doubleDeger(model['vade_orani']);
    if (vadeAy > 0 && vadeOrani > 0) {
      satisFiyati *= 1 + vadeOrani / 100;
    }
    return satisFiyati;
  }

  static List<Map<String, dynamic>> _gercekBirimliMaliyetKalemleri({
    required List<Map<String, dynamic>> maliyetKalemleri,
    required Map<String, Map<String, double>>? gerceklesenKalemleri,
    required int fallbackAdet,
  }) {
    return maliyetKalemleri.map((kalem) {
      final kod = kalem['kod']?.toString() ?? '';
      final gerceklesen = gerceklesenKalemleri?[kod];
      final tutar = gerceklesen?['tutar'] ?? 0;
      final miktar = gerceklesen?['miktar'] ?? 0;
      double gercekBirim = _doubleDeger(kalem['planBirim']);
      if (tutar > 0) {
        if (miktar > 0) {
          gercekBirim = tutar / miktar;
        } else if (fallbackAdet > 0) {
          gercekBirim = tutar / fallbackAdet;
        }
      }
      return {
        ...kalem,
        'gercekBirim': gercekBirim,
      };
    }).toList();
  }

  static String _maliyetKalemEtiketi(String kod) {
    const etiketler = {
      'iplik': 'İplik Maliyeti',
      'orgu': 'Örgü / Dokuma',
      'dikim': 'Dikim',
      'utu': 'Ütü',
      'yikama': 'Yıkama',
      'ilik_dugme': 'İlik Düğme',
      'fermuar': 'Fermuar',
      'baski_nakis': 'Baskı / Nakış',
      'nakis': 'Nakış / Baskı',
      'aksesuar': 'Aksesuar',
      'genel_aksesuar': 'Genel Aksesuar',
      'genel_gider': 'Genel Gider',
      'paketleme': 'Paketleme',
      'konfeksiyon': 'Konfeksiyon',
      'nakliye': 'Nakliye',
      'numune': 'Numune',
      'diger': 'Diğer',
    };
    return etiketler[kod] ?? kod;
  }

  /// Kâr/Zarar Analizi
  static Future<Map<String, dynamic>> getKarZararAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    RaporFiltresi? filtre,
  }) async {
    double toplamGelir = 0;
    double toplamGider = 0;
    double faturaGeliri = 0;
    double kasaGeliri = 0;
    double kasaGideri = 0;
    double depoSatisGeliri = 0;
    final Map<String, double> musteriBazliGelir = {};
    final Map<String, double> kategoriGelir = {};
    final Map<String, double> kategoriGider = {};
    final Map<String, double> markaBazliSatis = {};
    const faturaSayisi = 0;
    int hareketSayisi = 0;
    int depoSatisSayisi = 0;
    final modelKapsamiVar = filtre?.modelKapsamiVar ?? false;

    try {
      // 2. Kasa/banka hareketlerini getir
      if (!modelKapsamiVar) {
        try {
          var hareketQuery = _supabase
              .from(DbTables.kasaBankaHareketleri)
              .select('*')
              .eq('firma_id', _firmaId);
          if (baslangicTarihi != null) {
            hareketQuery = hareketQuery.gte(
                'tarih', baslangicTarihi.toIso8601String().split('T')[0]);
          }
          if (bitisTarihi != null) {
            hareketQuery = hareketQuery.lte(
                'tarih', bitisTarihi.toIso8601String().split('T')[0]);
          }
          final hareketler = await hareketQuery;
          hareketSayisi = hareketler.length;

          for (var hareket in hareketler) {
            final tutar = ((hareket['tutar'] ?? 0) as num).toDouble();
            final tip = hareket['islem_tipi']?.toString() ??
                hareket['hareket_tipi']?.toString() ??
                '';
            final kategori = hareket['kategori']?.toString() ??
                hareket['aciklama']?.toString() ??
                'Diğer';

            if (tip == 'gelir' || tip == 'giris' || tip == 'tahsilat') {
              kasaGeliri += tutar;
              kategoriGelir[kategori] = (kategoriGelir[kategori] ?? 0) + tutar;
            } else if (tip == 'gider' || tip == 'cikis' || tip == 'odeme') {
              kasaGideri += tutar;
              kategoriGider[kategori] = (kategoriGider[kategori] ?? 0) + tutar;
            }
          }
        } catch (e) {
          AppLogger.debug('Veri isleme hatasi: $e');
        }
      }

      // 3. Ürün Depo Satışlarını getir
      try {
        final depoQuery = _supabase
            .from(DbTables.urunDepo)
            .select('*')
            .eq('firma_id', _firmaId);
        final depoVerileri = await depoQuery;

        for (var kayit in depoVerileri) {
          if (filtre != null && !filtre.depoEslesir(kayit)) continue;

          // satilan_tutar, satilan_adet veya benzeri sütunları kontrol et
          final satilanTutar =
              ((kayit['satilan_tutar'] ?? 0) as num).toDouble();
          final satilanAdet = ((kayit['satilan_adet'] ?? 0) as num).toInt();
          final birimFiyat =
              ((kayit['birim_fiyat'] ?? kayit['satis_fiyati'] ?? 0) as num)
                  .toDouble();

          double tutar = satilanTutar;
          if (tutar == 0 && satilanAdet > 0 && birimFiyat > 0) {
            tutar = satilanAdet * birimFiyat;
          }

          if (tutar > 0) {
            depoSatisGeliri += tutar;
            depoSatisSayisi++;

            final marka = kayit['marka']?.toString() ?? 'Diğer';
            markaBazliSatis[marka] = (markaBazliSatis[marka] ?? 0) + tutar;
          }
        }
      } catch (e) {
        AppLogger.debug('Veri isleme hatasi: $e');
      }

      // 4. Model bazlı gelir (triko_takip tablosundan satış fiyatları)
      double modelMaliyeti = 0; // Model üretim maliyetleri
      try {
        var modelQuery = _supabase.from(DbTables.trikoTakip).select('''
          id, marka, adet, toplam_adet, yuklenen_adet, pesin_fiyat, item_no,
          iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat,
          ilik_dugme_fiyat, aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, fermuar_fiyat
        ''').eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          modelQuery =
              modelQuery.gte('created_at', baslangicTarihi.toIso8601String());
        }
        if (bitisTarihi != null) {
          modelQuery =
              modelQuery.lte('created_at', bitisTarihi.toIso8601String());
        }
        if (filtre?.marka != null) {
          modelQuery = modelQuery.eq('marka', filtre!.marka!);
        }
        if (filtre?.model != null) {
          modelQuery = modelQuery.eq('item_no', filtre!.model!);
        }
        if (filtre?.yil != null) {
          modelQuery = modelQuery
              .gte('created_at', DateTime(filtre!.yil!, 1, 1).toIso8601String())
              .lt('created_at',
                  DateTime(filtre.yil! + 1, 1, 1).toIso8601String());
        }
        final modeller = await modelQuery;
        final modelIds = modeller
            .map((model) => model['id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();
        final Map<String, Map<String, dynamic>> ozetByModelId = {};
        if (modelIds.isNotEmpty) {
          final ozetler = await _supabase
              .from(DbTables.modelKarlilikOzetleri)
              .select('*')
              .eq('firma_id', _firmaId)
              .inFilter('model_id', modelIds);
          for (final ozet in ozetler) {
            final modelId = ozet['model_id']?.toString();
            if (modelId != null && modelId.isNotEmpty) {
              ozetByModelId[modelId] = Map<String, dynamic>.from(ozet);
            }
          }
        }

        double modelSatisGeliri = 0;
        for (var model in modeller) {
          final modelId = model['id']?.toString();
          final dbOzet = modelId == null ? null : ozetByModelId[modelId];
          if (dbOzet != null) {
            final gelir = _doubleDeger(dbOzet['satis_geliri']);
            final maliyet = _doubleDeger(dbOzet['gercek_toplam_maliyet']);
            modelSatisGeliri += gelir;
            modelMaliyeti += maliyet;
            if (gelir > 0) {
              final marka = model['marka']?.toString() ?? 'Diğer';
              musteriBazliGelir[marka] =
                  (musteriBazliGelir[marka] ?? 0) + gelir;
            }
            continue;
          }

          final yuklenenAdet = ((model['yuklenen_adet'] ?? 0) as num).toInt();
          final fiyat = ((model['pesin_fiyat'] ?? 0) as num).toDouble();
          // Sadece yüklenen adet üzerinden hesapla
          final hesapAdet = yuklenenAdet > 0 ? yuklenenAdet : 0;
          modelSatisGeliri += hesapAdet * fiyat;

          // Model maliyetlerini hesapla
          final iplik = ((model['iplik_maliyeti'] ?? 0) as num).toDouble();
          final orgu = ((model['orgu_fiyat'] ?? 0) as num).toDouble();
          final dikim = ((model['dikim_fiyat'] ?? 0) as num).toDouble();
          final utu = ((model['utu_fiyat'] ?? 0) as num).toDouble();
          final yikama = ((model['yikama_fiyat'] ?? 0) as num).toDouble();
          final ilikDugme =
              ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
          final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelAksesuar =
              ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelGider =
              ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
          final fermuar = ((model['fermuar_fiyat'] ?? 0) as num).toDouble();

          final birimMaliyet = iplik +
              orgu +
              dikim +
              utu +
              yikama +
              ilikDugme +
              aksesuar +
              genelAksesuar +
              genelGider +
              fermuar;
          modelMaliyeti += birimMaliyet * hesapAdet;

          if (hesapAdet > 0) {
            final marka = model['marka']?.toString() ?? 'Diğer';
            musteriBazliGelir[marka] =
                (musteriBazliGelir[marka] ?? 0) + (hesapAdet * fiyat);
          }
        }

        // Model maliyetlerini kategori giderine ekle
        if (modelMaliyeti > 0) {
          kategoriGider['Üretim Maliyeti'] =
              (kategoriGider['Üretim Maliyeti'] ?? 0) + modelMaliyeti;
        }

        // Model satış gelirini kategori gelirine ekle
        if (modelSatisGeliri > 0) {
          kategoriGelir['Satış'] =
              (kategoriGelir['Satış'] ?? 0) + modelSatisGeliri;
        }

        // Eğer fatura geliri yoksa model satış gelirini kullan
        if (faturaGeliri == 0) {
          faturaGeliri = modelSatisGeliri;
        }
      } catch (e) {
        AppLogger.debug('Veri isleme hatasi: $e');
      }

      // Depo satışlarını kategori gelirine ekle
      if (depoSatisGeliri > 0) {
        kategoriGelir['Ürün Depo Satışı'] = depoSatisGeliri;
      }

      toplamGelir = faturaGeliri + kasaGeliri + depoSatisGeliri;
      toplamGider = kasaGideri + modelMaliyeti;
      final brutKar = toplamGelir - toplamGider;
      final karMarji = toplamGelir > 0 ? (brutKar / toplamGelir) * 100 : 0;

      return {
        'toplamGelir': toplamGelir,
        'toplamGider': toplamGider,
        'brutKar': brutKar,
        'karMarji': karMarji,
        'faturaGeliri': faturaGeliri,
        'kasaGeliri': kasaGeliri,
        'kasaGideri': kasaGideri,
        'depoSatisGeliri': depoSatisGeliri,
        'markaBazliSatis': markaBazliSatis,
        'musteriBazliGelir': musteriBazliGelir,
        'kategoriGelir': kategoriGelir,
        'kategoriGider': kategoriGider,
        'faturaSayisi': faturaSayisi,
        'hareketSayisi': hareketSayisi,
        'depoSatisSayisi': depoSatisSayisi,
        'demoVeri': false,
      };
    } catch (e) {
      debugPrint('getKarZararAnalizi HATA: $e');
      return {
        'toplamGelir': 0.0,
        'toplamGider': 0.0,
        'brutKar': 0.0,
        'karMarji': 0.0,
        'faturaGeliri': 0.0,
        'kasaGeliri': 0.0,
        'kasaGideri': 0.0,
        'depoSatisGeliri': 0.0,
        'markaBazliSatis': <String, double>{},
        'musteriBazliGelir': <String, double>{},
        'kategoriGelir': <String, double>{},
        'kategoriGider': <String, double>{},
        'faturaSayisi': 0,
        'hareketSayisi': 0,
        'depoSatisSayisi': 0,
        'demoVeri': false,
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // TEDARİKÇİ PERFORMANS ANALİZİ
  // ==============================================

  static Future<Map<String, dynamic>> getTedarikciPerformansAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      // Tedarikçileri getir
      final tedarikciler = await _supabase
          .from(DbTables.tedarikciler)
          .select('*')
          .eq('firma_id', _firmaId);

      // Her tedarikçi için atama verilerini topla
      final List<Map<String, dynamic>> tedarikciPerformanslari = [];

      for (var tedarikci in tedarikciler) {
        final tedarikciId = tedarikci['id'];
        final faaliyet = tedarikci['faaliyet'] ?? '';

        // İlgili atama tablosunu belirle
        String atamaTablosu = '';
        switch (faaliyet.toString().toLowerCase()) {
          case 'dokuma':
            atamaTablosu = DbTables.dokumaAtamalari;
            break;
          case 'konfeksiyon':
            atamaTablosu = DbTables.konfeksiyonAtamalari;
            break;
          case 'yıkama':
          case 'yikama':
            atamaTablosu = DbTables.yikamaAtamalari;
            break;
          case 'nakış':
          case 'nakis':
            atamaTablosu = DbTables.nakisAtamalari;
            break;
          case 'ütü':
          case 'utu':
            atamaTablosu = DbTables.utuAtamalari;
            break;
          case 'ilik düğme':
          case 'ilik_dugme':
            atamaTablosu = DbTables.ilikDugmeAtamalari;
            break;
          default:
            continue;
        }

        try {
          var query = _supabase
              .from(atamaTablosu)
              .select('id, durum, atama_tarihi, tamamlama_tarihi')
              .eq('firma_id', _firmaId)
              .eq('tedarikci_id', tedarikciId);
          if (baslangicTarihi != null) {
            query =
                query.gte('atama_tarihi', baslangicTarihi.toIso8601String());
          }
          if (bitisTarihi != null) {
            query = query.lte('atama_tarihi', bitisTarihi.toIso8601String());
          }

          final atamalar = await query;

          final int toplamAtama = atamalar.length;
          final int tamamlanan =
              atamalar.where((a) => a['durum'] == 'tamamlandi').length;
          final int devamEden = atamalar
              .where(
                  (a) => a['durum'] == 'uretimde' || a['durum'] == 'onaylandi')
              .length;
          final int bekleyen = atamalar
              .where((a) => a['durum'] == 'atandi' || a['durum'] == null)
              .length;

          // Ortalama tamamlama süresi
          double toplamSure = 0;
          int sureliAtama = 0;
          for (var atama in atamalar) {
            if (atama['atama_tarihi'] != null &&
                atama['tamamlama_tarihi'] != null) {
              final baslangic = DateTime.parse(atama['atama_tarihi']);
              final bitis = DateTime.parse(atama['tamamlama_tarihi']);
              toplamSure += bitis.difference(baslangic).inHours;
              sureliAtama++;
            }
          }
          final ortalamaSure = sureliAtama > 0 ? toplamSure / sureliAtama : 0;

          tedarikciPerformanslari.add({
            'id': tedarikciId,
            'sirket': tedarikci['sirket'] ?? '',
            'faaliyet': faaliyet,
            'toplamAtama': toplamAtama,
            'tamamlanan': tamamlanan,
            'devamEden': devamEden,
            'bekleyen': bekleyen,
            'tamamlanmaOrani':
                toplamAtama > 0 ? (tamamlanan / toplamAtama) * 100 : 0,
            'ortalamaTamamlamaSuresi': ortalamaSure,
          });
        } catch (e) {
          // Tablo yoksa atla
          continue;
        }
      }

      // Performansa göre sırala
      tedarikciPerformanslari.sort((a, b) => (b['tamamlanmaOrani'] as double)
          .compareTo(a['tamamlanmaOrani'] as double));

      return {
        'tedarikciPerformanslari': tedarikciPerformanslari,
        'toplamTedarikci': tedarikciPerformanslari.length,
        'ortalamaPerformans': tedarikciPerformanslari.isNotEmpty
            ? tedarikciPerformanslari.fold(
                    0.0, (sum, t) => sum + (t['tamamlanmaOrani'] as double)) /
                tedarikciPerformanslari.length
            : 0,
      };
    } catch (e) {
      return {
        'tedarikciPerformanslari': <Map<String, dynamic>>[],
        'toplamTedarikci': 0,
        'ortalamaPerformans': 0.0,
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // ÜRETİM VERİMLİLİK ANALİZİ
  // ==============================================

  static Future<Map<String, dynamic>> getUretimVerimlilikAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      // Tüm atama tablolarından veri çek
      final tablolar = [
        DbTables.dokumaAtamalari,
        DbTables.konfeksiyonAtamalari,
        DbTables.yikamaAtamalari,
        DbTables.nakisAtamalari,
        DbTables.utuAtamalari,
        DbTables.ilikDugmeAtamalari,
      ];

      final Map<String, Map<String, dynamic>> asamaVerileri = {};

      for (var tablo in tablolar) {
        try {
          var query = _supabase
              .from(tablo)
              .select(
                  'id, durum, atama_tarihi, tamamlama_tarihi, tamamlanan_adet')
              .eq('firma_id', _firmaId);
          if (baslangicTarihi != null) {
            query =
                query.gte('atama_tarihi', baslangicTarihi.toIso8601String());
          }
          if (bitisTarihi != null) {
            query = query.lte('atama_tarihi', bitisTarihi.toIso8601String());
          }
          final response = await query;

          final asamaAdi = tablo
              .replaceAll('_atamalari', '')
              .replaceAll('_', ' ')
              .capitalize();

          final int toplam = response.length;
          final int tamamlanan =
              response.where((r) => r['durum'] == 'tamamlandi').length;
          final int uretimde =
              response.where((r) => r['durum'] == 'uretimde').length;
          final int bekleyen = response
              .where((r) => r['durum'] == 'atandi' || r['durum'] == null)
              .length;
          final int tamamlananAdet = response.fold(
              0, (sum, r) => sum + ((r['tamamlanan_adet'] ?? 0) as int));

          asamaVerileri[asamaAdi] = {
            'toplam': toplam,
            'tamamlanan': tamamlanan,
            'uretimde': uretimde,
            'bekleyen': bekleyen,
            'tamamlananAdet': tamamlananAdet,
            'verimlilik': toplam > 0 ? (tamamlanan / toplam) * 100 : 0,
          };
        } catch (e) {
          // Tablo yoksa atla
          continue;
        }
      }

      // Genel verimlilik hesapla
      final int toplamIs =
          asamaVerileri.values.fold(0, (sum, v) => sum + (v['toplam'] as int));
      final int toplamTamamlanan = asamaVerileri.values
          .fold(0, (sum, v) => sum + (v['tamamlanan'] as int));
      final double genelVerimlilik =
          toplamIs > 0 ? (toplamTamamlanan / toplamIs) * 100 : 0;

      return {
        'asamaVerileri': asamaVerileri,
        'toplamIs': toplamIs,
        'toplamTamamlanan': toplamTamamlanan,
        'genelVerimlilik': genelVerimlilik,
      };
    } catch (e) {
      return {
        'asamaVerileri': <String, Map<String, dynamic>>{},
        'toplamIs': 0,
        'toplamTamamlanan': 0,
        'genelVerimlilik': 0.0,
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // MARKA BAZLI ANALİZ
  // ==============================================

  static Future<Map<String, dynamic>> getMarkaBazliAnaliz({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    RaporFiltresi? filtre,
  }) async {
    try {
      var query = _supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', _firmaId);

      if (baslangicTarihi != null) {
        query = query.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('created_at', bitisTarihi.toIso8601String());
      }
      if (filtre?.marka != null) {
        query = query.eq('marka', filtre!.marka!);
      }
      if (filtre?.model != null) {
        query = query.eq('item_no', filtre!.model!);
      }
      if (filtre?.yil != null) {
        query = query
            .gte('created_at', DateTime(filtre!.yil!, 1, 1).toIso8601String())
            .lt('created_at',
                DateTime(filtre.yil! + 1, 1, 1).toIso8601String());
      }

      final modeller = await query;

      final Map<String, Map<String, dynamic>> markaVerileri = {};

      for (var model in modeller) {
        final marka = model['marka'] ?? 'Bilinmeyen';
        final adet =
            ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
        final yuklenenAdet = ((model['yuklenen_adet'] ?? 0) as num).toInt();
        // pesin_fiyat kullan (satis_fiyati yerine)
        final satisFiyati =
            ((model['pesin_fiyat'] ?? model['satis_fiyati'] ?? 0) as num)
                .toDouble();
        // Birim maliyet hesapla
        final iplik = ((model['iplik_maliyeti'] ?? 0) as num).toDouble();
        final orgu = ((model['orgu_fiyat'] ?? 0) as num).toDouble();
        final dikim = ((model['dikim_fiyat'] ?? 0) as num).toDouble();
        final utu = ((model['utu_fiyat'] ?? 0) as num).toDouble();
        final yikama = ((model['yikama_fiyat'] ?? 0) as num).toDouble();
        final ilikDugme = ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
        final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
        final genelAksesuar =
            ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
        final genelGider =
            ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
        final birimMaliyet = iplik +
            orgu +
            dikim +
            utu +
            yikama +
            ilikDugme +
            aksesuar +
            genelAksesuar +
            genelGider;

        // Sadece yüklenen adet üzerinden satış/maliyet hesapla
        final hesapAdet = yuklenenAdet > 0 ? yuklenenAdet : 0;

        if (!markaVerileri.containsKey(marka)) {
          markaVerileri[marka] = {
            'modelSayisi': 0,
            'toplamAdet': 0,
            'yuklenenAdet': 0,
            'toplamSatis': 0.0,
            'toplamMaliyet': 0.0,
          };
        }

        markaVerileri[marka]!['modelSayisi'] =
            (markaVerileri[marka]!['modelSayisi'] as int) + 1;
        markaVerileri[marka]!['toplamAdet'] =
            (markaVerileri[marka]!['toplamAdet'] as int) + adet;
        markaVerileri[marka]!['yuklenenAdet'] =
            (markaVerileri[marka]!['yuklenenAdet'] as int) + yuklenenAdet;
        markaVerileri[marka]!['toplamSatis'] =
            (markaVerileri[marka]!['toplamSatis'] as double) +
                (satisFiyati * hesapAdet);
        markaVerileri[marka]!['toplamMaliyet'] =
            (markaVerileri[marka]!['toplamMaliyet'] as double) +
                (birimMaliyet * hesapAdet);
      }

      // Kar hesapla
      markaVerileri.forEach((marka, veri) {
        final satis = veri['toplamSatis'] as double;
        final maliyet = veri['toplamMaliyet'] as double;
        veri['kar'] = satis - maliyet;
        veri['karMarji'] = satis > 0 ? ((satis - maliyet) / satis) * 100 : 0;
      });

      // En çok sipariş alan markaları sırala
      final siraliMarkalar = markaVerileri.entries.toList()
        ..sort((a, b) => (b.value['toplamAdet'] as int)
            .compareTo(a.value['toplamAdet'] as int));

      return {
        'markaVerileri': Map.fromEntries(siraliMarkalar),
        'toplamMarka': markaVerileri.length,
        'toplamModel': modeller.length,
      };
    } catch (e) {
      return {
        'markaVerileri': <String, Map<String, dynamic>>{},
        'toplamMarka': 0,
        'toplamModel': 0,
        'hata': e.toString(),
      };
    }
  }
}

// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
