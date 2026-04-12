import 'package:flutter/material.dart' show DateTimeRange;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Üretim raporu verilerini yöneten servis katmanı.
///
/// N+1 sorgu problemi çözümü: Her aşama için toplu sorgu yapılır,
/// ardından client-side eşleştirme uygulanır.
class UretimRaporuService {
  final SupabaseClient _supabase;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  UretimRaporuService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Tüm aşama tablolarının adları ve select alanları
  static const _asamaTablolari = {
    'dokuma': {
      'tablo': DbTables.dokumaAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, fire_adet, talep_edilen_adet, tedarikci_id, created_at',
    },
    'nakis': {
      'tablo': DbTables.nakisAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, fire_adet, talep_edilen_adet, tedarikci_id, created_at',
    },
    'konfeksiyon': {
      'tablo': DbTables.konfeksiyonAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, fire_adet, talep_edilen_adet, tedarikci_id, created_at',
    },
    'yikama': {
      'tablo': DbTables.yikamaAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, fire_adet, talep_edilen_adet, tedarikci_id, created_at',
    },
    'utu': {
      'tablo': DbTables.utuAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, fire_adet, talep_edilen_adet, tedarikci_id, created_at',
    },
    'ilik_dugme': {
      'tablo': DbTables.ilikDugmeAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, fire_adet, talep_edilen_adet, tedarikci_id, created_at',
    },
    'kalite_kontrol': {
      'tablo': DbTables.kaliteKontrolAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, kontrol_edilecek_adet, created_at',
    },
    'paketleme': {
      'tablo': DbTables.paketlemeAtamalari,
      'select': 'model_id, durum, tamamlanan_adet, talep_edilen_adet, created_at',
    },
  };

  /// Üretim aşama sırası
  static const asamaSirasi = [
    'dokuma',
    'konfeksiyon',
    'yikama',
    'utu',
    'ilik_dugme',
    'kalite_kontrol',
    'paketleme',
  ];

  /// Tüm modelleri ve aşama verilerini toplu olarak çeker.
  /// N+1 yerine 9 sorgu (1 model + 8 aşama) ile tamamlanır.
  Future<UretimRaporuData> verileriYukle() async {
    try {
      // 1. Tüm modelleri çek
      final modeller = await _supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', _firmaId)
          .order('created_at', ascending: false);

      // 2. Tüm aşama tablolarını paralel olarak çek
      final asamaVerileri = <String, List<Map<String, dynamic>>>{};

      final futures = _asamaTablolari.entries.map((entry) async {
        try {
          final data = await _supabase
              .from(entry.value['tablo']!)
              .select(entry.value['select']!)
              .eq('firma_id', _firmaId);
          return MapEntry(entry.key, List<Map<String, dynamic>>.from(data));
        } catch (e) {
          AppLogger.debug('${entry.key} tablosu yüklenemedi: $e');
          return MapEntry(entry.key, <Map<String, dynamic>>[]);
        }
      });

      final results = await Future.wait(futures);
      for (final result in results) {
        asamaVerileri[result.key] = result.value;
      }

      // 3. Tedarikçileri çek
      List<Map<String, dynamic>> tedarikciler = [];
      try {
        tedarikciler = List<Map<String, dynamic>>.from(
          await _supabase.from(DbTables.tedarikciler).select('id, firma_adi').eq('firma_id', _firmaId),
        );
      } catch (e) {
        AppLogger.debug('Tedarikçiler yüklenemedi: $e');
      }

      // 4. Modelleri aşama verileriyle zenginleştir
      final zenginModeller = _modelleriZenginlestir(
        List<Map<String, dynamic>>.from(modeller),
        asamaVerileri,
        tedarikciler,
      );

      // 5. Marka listesini oluştur
      final markalar = <String>{'Tümü'};
      for (var model in modeller) {
        if (model['marka'] != null && model['marka'].toString().isNotEmpty) {
          markalar.add(model['marka'].toString());
        }
      }

      return UretimRaporuData(
        modeller: zenginModeller,
        markaListesi: markalar.toList()..sort(),
        tedarikciler: tedarikciler,
      );
    } catch (e) {
      throw NetworkException('Veriler yüklenirken hata oluştu: $e',
          originalError: e);
    }
  }

  /// Modelleri aşama verileriyle eşleştirir (client-side join)
  List<Map<String, dynamic>> _modelleriZenginlestir(
    List<Map<String, dynamic>> modeller,
    Map<String, List<Map<String, dynamic>>> asamaVerileri,
    List<Map<String, dynamic>> tedarikciler,
  ) {
    // Model bazlı aşama verilerini indexle (en son kayıt)
    final modelAsamaIndex =
        <String, Map<String, Map<String, dynamic>>>{};

    for (final entry in asamaVerileri.entries) {
      final asamaKey = entry.key;
      for (final atama in entry.value) {
        final modelId = atama['model_id']?.toString();
        if (modelId == null) continue;

        modelAsamaIndex.putIfAbsent(modelId, () => {});
        // İlk gelen en güncel (sorgular desc sıralı değil, hepsini alıyoruz)
        // En son created_at'ı seç
        final mevcut = modelAsamaIndex[modelId]![asamaKey];
        if (mevcut == null) {
          modelAsamaIndex[modelId]![asamaKey] = atama;
        } else {
          final mevcutTarih =
              DateTime.tryParse(mevcut['created_at']?.toString() ?? '');
          final yeniTarih =
              DateTime.tryParse(atama['created_at']?.toString() ?? '');
          if (yeniTarih != null &&
              (mevcutTarih == null || yeniTarih.isAfter(mevcutTarih))) {
            modelAsamaIndex[modelId]![asamaKey] = atama;
          }
        }
      }
    }

    // Tedarikçi index
    final tedarikciIndex = <String, String>{};
    for (final t in tedarikciler) {
      tedarikciIndex[t['id']?.toString() ?? ''] =
          t['firma_adi']?.toString() ?? '';
    }

    final zenginModeller = <Map<String, dynamic>>[];

    for (var model in modeller) {
      final modelId = model['id']?.toString() ?? '';
      final asamaDurumlari =
          modelAsamaIndex[modelId] ?? <String, Map<String, dynamic>>{};

      // Eksik aşamalara boş map ekle
      for (final asamaKey in asamaSirasi) {
        asamaDurumlari.putIfAbsent(asamaKey, () => {});
      }

      final mevcutAsama = _mevcutAsamayiBelirle(asamaDurumlari);

      // Tedarikçi bilgisini mevcut aşamadan al
      String tedarikciAdi = '';
      final mevcutAsamaData = asamaDurumlari[mevcutAsama];
      if (mevcutAsamaData != null &&
          mevcutAsamaData['tedarikci_id'] != null) {
        tedarikciAdi =
            tedarikciIndex[mevcutAsamaData['tedarikci_id'].toString()] ?? '';
      }

      zenginModeller.add({
        ...model,
        'asamalar': asamaDurumlari,
        'mevcut_asama': mevcutAsama,
        'tedarikci_adi': tedarikciAdi,
      });
    }

    // Tahmini tamamlanma tarihi hesapla
    _tahminiTamamlanmaTarihiHesapla(zenginModeller);

    return zenginModeller;
  }

  /// Tahmini tamamlanma tarihi - tamamlanmış modellerin aşama sürelerinden hesaplar
  void _tahminiTamamlanmaTarihiHesapla(List<Map<String, dynamic>> modeller) {
    // Tamamlanan modellerden aşama başına ortalama süre hesapla
    int toplamSure = 0;
    int toplamTamamlanan = 0;
    for (final model in modeller) {
      if (model['mevcut_asama'] == 'tamamlandi' && model['created_at'] != null) {
        final baslangic = DateTime.tryParse(model['created_at'].toString());
        final bitis = DateTime.tryParse(model['updated_at']?.toString() ?? '');
        if (baslangic != null && bitis != null) {
          toplamSure += bitis.difference(baslangic).inDays;
          toplamTamamlanan++;
        }
      }
    }
    
    // Aşama başına ortalama gün (toplam süre / toplam aşama sayısı)
    final ortalamaAsamaGun = toplamTamamlanan > 0
        ? toplamSure / (toplamTamamlanan * asamaSirasi.length)
        : 5.0; // Varsayılan: aşama başına 5 gün
    
    for (final model in modeller) {
      if (model['mevcut_asama'] == 'tamamlandi') {
        model['tahmini_tamamlanma'] = null; // Zaten tamamlandı
        continue;
      }
      
      final mevcutAsama = model['mevcut_asama'] as String? ?? 'beklemede';
      final mevcutAsamaIdx = asamaSirasi.indexOf(mevcutAsama);
      if (mevcutAsamaIdx < 0) {
        // Henüz üretime başlanmamış (beklemede)
        final kalanGun = (asamaSirasi.length * ortalamaAsamaGun).ceil();
        model['tahmini_tamamlanma'] = DateTime.now().add(Duration(days: kalanGun)).toIso8601String();
        continue;
      }
      final kalanAsamaSayisi = asamaSirasi.length - mevcutAsamaIdx;
      final kalanGun = (kalanAsamaSayisi * ortalamaAsamaGun).ceil();
      model['tahmini_tamamlanma'] = DateTime.now().add(Duration(days: kalanGun)).toIso8601String();
    }
  }

  /// Modelin mevcut üretim aşamasını belirler
  String _mevcutAsamayiBelirle(
      Map<String, Map<String, dynamic>> asamalar) {
    String? aktifAsama;
    bool tumAsamalarTamamlandi = true;
    bool hicAsamaAtanmamis = true;

    for (int i = asamaSirasi.length - 1; i >= 0; i--) {
      final asamaKey = asamaSirasi[i];
      final asamaData = asamalar[asamaKey] ?? {};
      final durum = asamaData['durum']?.toString() ?? '';

      if (durum.isNotEmpty && durum != 'beklemede') {
        hicAsamaAtanmamis = false;
      }

      if (durum == 'uretimde' ||
          durum == 'isleniyor' ||
          durum == 'atandi' ||
          durum == 'onaylandi') {
        aktifAsama = asamaKey;
      }

      if (durum != 'tamamlandi') {
        tumAsamalarTamamlandi = false;
      }
    }

    if (tumAsamalarTamamlandi) return 'tamamlandi';
    if (hicAsamaAtanmamis) return 'beklemede';
    if (aktifAsama != null) return aktifAsama;

    for (var asamaKey in asamaSirasi) {
      final asamaData = asamalar[asamaKey] ?? {};
      final durum = asamaData['durum']?.toString() ?? '';
      if (durum.isEmpty || durum == 'beklemede') {
        return asamaKey;
      }
    }

    return 'beklemede';
  }

  /// Client-side filtreleme uygular
  static UretimRaporuFiltreSonuc filtrele({
    required List<Map<String, dynamic>> tumModeller,
    required String secilenMarka,
    required String secilenDurum,
    required String secilenAsama,
    required String aramaMetni,
    DateTimeRange? tarihAraligi,
  }) {
    var filtrelenmis = tumModeller.toList();

    // Marka filtresi
    if (secilenMarka != 'Tümü') {
      filtrelenmis =
          filtrelenmis.where((m) => m['marka'] == secilenMarka).toList();
    }

    // Tarih filtresi
    if (tarihAraligi != null) {
      filtrelenmis = filtrelenmis.where((m) {
        final createdAt = DateTime.tryParse(m['created_at'] ?? '');
        if (createdAt == null) return true;
        return !createdAt.isBefore(tarihAraligi.start) &&
            !createdAt.isAfter(
                tarihAraligi.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Durum filtresi
    if (secilenDurum != 'Tümü') {
      filtrelenmis = filtrelenmis.where((m) {
        final tamamlandi = m['tamamlandi'] == true;
        return secilenDurum == 'Tamamlanan' ? tamamlandi : !tamamlandi;
      }).toList();
    }

    // Aşama filtresi
    if (secilenAsama != 'Tümü') {
      filtrelenmis = filtrelenmis
          .where((m) => m['mevcut_asama'] == secilenAsama)
          .toList();
    }

    // Arama filtresi
    if (aramaMetni.isNotEmpty) {
      final arama = aramaMetni.toLowerCase();
      filtrelenmis = filtrelenmis.where((m) {
        final marka = m['marka']?.toString().toLowerCase() ?? '';
        final itemNo = m['item_no']?.toString().toLowerCase() ?? '';
        final renk = m['renk']?.toString().toLowerCase() ?? '';
        return marka.contains(arama) ||
            itemNo.contains(arama) ||
            renk.contains(arama);
      }).toList();
    }

    // Özet hesapla
    final ozet = _ozetHesapla(filtrelenmis);

    return UretimRaporuFiltreSonuc(
      modeller: filtrelenmis,
      ozet: ozet,
    );
  }

  /// Filtrelenmiş modeller için özet istatistikleri hesaplar
  static Map<String, dynamic> _ozetHesapla(
      List<Map<String, dynamic>> modeller) {
    final int toplamModel = modeller.length;
    final int tamamlanan =
        modeller.where((m) => m['tamamlandi'] == true).length;
    final int devamEden = toplamModel - tamamlanan;
    final int toplamAdet =
        modeller.fold(0, (sum, m) => sum + ((m['adet'] ?? 0) as int));
    int toplamFire = 0;
    int gecikenSiparis = 0;
    final now = DateTime.now();

    final Map<String, Map<String, int>> fireAnaliz = {
      'dokuma': {'fire': 0, 'toplam': 0},
      'nakis': {'fire': 0, 'toplam': 0},
      'konfeksiyon': {'fire': 0, 'toplam': 0},
      'yikama': {'fire': 0, 'toplam': 0},
      'utu': {'fire': 0, 'toplam': 0},
      'ilik_dugme': {'fire': 0, 'toplam': 0},
      'kalite_kontrol': {'fire': 0, 'toplam': 0},
      'paketleme': {'fire': 0, 'toplam': 0},
    };

    final Map<String, int> asamaSayilari = {
      'beklemede': 0,
      'dokuma': 0,
      'konfeksiyon': 0,
      'yikama': 0,
      'utu': 0,
      'ilik_dugme': 0,
      'kalite_kontrol': 0,
      'paketleme': 0,
      'tamamlandi': 0,
    };

    // Tedarikçi bazlı istatistik
    final Map<String, Map<String, dynamic>> tedarikciIstatistik = {};

    for (var model in modeller) {
      final asamalar =
          model['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};

      // Fire hesapla
      for (var entry in asamalar.entries) {
        final asamaKey = entry.key;
        final asama = entry.value;
        final fire = (asama['fire_adet'] ?? 0) as int;
        final talep = (asama['talep_edilen_adet'] ??
            asama['kontrol_edilecek_adet'] ??
            0) as int;
        toplamFire += fire;

        if (fireAnaliz.containsKey(asamaKey)) {
          fireAnaliz[asamaKey]!['fire'] =
              fireAnaliz[asamaKey]!['fire']! + fire;
          fireAnaliz[asamaKey]!['toplam'] =
              fireAnaliz[asamaKey]!['toplam']! + talep;
        }
      }

      // Aşama sayıları
      final mevcutAsama = model['mevcut_asama'] as String? ?? 'beklemede';
      if (asamaSayilari.containsKey(mevcutAsama)) {
        asamaSayilari[mevcutAsama] = asamaSayilari[mevcutAsama]! + 1;
      }

      // Termin kontrolü
      final terminStr = model['termin_tarihi']?.toString();
      if (terminStr != null && terminStr.isNotEmpty) {
        final termin = DateTime.tryParse(terminStr);
        if (termin != null &&
            termin.isBefore(now) &&
            model['tamamlandi'] != true) {
          gecikenSiparis++;
        }
      }

      // Tedarikçi istatistik
      final tedarikciAdi =
          model['tedarikci_adi']?.toString() ?? '';
      if (tedarikciAdi.isNotEmpty) {
        tedarikciIstatistik.putIfAbsent(
            tedarikciAdi,
            () => {
                  'toplam_model': 0,
                  'toplam_adet': 0,
                  'toplam_fire': 0,
                  'tamamlanan': 0,
                  'geciken': 0,
                  'performans_puani': 0.0,
                });
        tedarikciIstatistik[tedarikciAdi]!['toplam_model'] =
            (tedarikciIstatistik[tedarikciAdi]!['toplam_model'] as int) + 1;
        tedarikciIstatistik[tedarikciAdi]!['toplam_adet'] =
            (tedarikciIstatistik[tedarikciAdi]!['toplam_adet'] as int) +
                ((model['adet'] ?? 0) as int);
        if (model['tamamlandi'] == true) {
          tedarikciIstatistik[tedarikciAdi]!['tamamlanan'] =
              (tedarikciIstatistik[tedarikciAdi]!['tamamlanan'] as int) + 1;
        }
        // Fire
        int modelFire = 0;
        final asamalar = model['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};
        for (var a in asamalar.values) { modelFire += (a['fire_adet'] ?? 0) as int; }
        tedarikciIstatistik[tedarikciAdi]!['toplam_fire'] =
            (tedarikciIstatistik[tedarikciAdi]!['toplam_fire'] as int) + modelFire;
        // Gecikme
        if (terminStr != null && terminStr.isNotEmpty) {
          final termin = DateTime.tryParse(terminStr);
          if (termin != null && termin.isBefore(now) && model['tamamlandi'] != true) {
            tedarikciIstatistik[tedarikciAdi]!['geciken'] =
                (tedarikciIstatistik[tedarikciAdi]!['geciken'] as int) + 1;
          }
        }
      }
    }

    // Tedarikçi performans puanı hesapla (0-100)
    // Ağırlıklar: tamamlanma %40, fire %30, gecikme %30
    for (final entry in tedarikciIstatistik.entries) {
      final data = entry.value;
      final topM = (data['toplam_model'] as int);
      final tamam = (data['tamamlanan'] as int);
      final fireT = (data['toplam_fire'] as int);
      final adetT = (data['toplam_adet'] as int);
      final gecik = (data['geciken'] as int);
      
      final tamamOran = topM > 0 ? (tamam / topM * 100) : 0.0;
      final fireOrn = adetT > 0 ? (fireT / adetT * 100) : 0.0;
      final gecikOran = topM > 0 ? (gecik / topM * 100) : 0.0;
      
      // Puan: 100 - (fire penalty) - (gecikme penalty) + (tamamlanma bonus)
      final puan = (tamamOran * 0.4) + ((100 - fireOrn.clamp(0, 100)) * 0.3) + ((100 - gecikOran.clamp(0, 100)) * 0.3);
      data['performans_puani'] = puan.clamp(0, 100).roundToDouble();
    }

    // KPI metrikleri hesapla
    final double verimlilikOrani = toplamAdet > 0
        ? ((toplamAdet - toplamFire) / toplamAdet * 100)
        : 100.0;
    final double zamanindaTeslimOrani = toplamModel > 0
        ? ((toplamModel - gecikenSiparis) / toplamModel * 100)
        : 100.0;
    final double fireOrani =
        toplamAdet > 0 ? (toplamFire / toplamAdet * 100) : 0.0;
    final double tamamlanmaOrani =
        toplamModel > 0 ? (tamamlanan / toplamModel * 100) : 0.0;

    // Ortalama üretim süresi (tamamlanan modeller)
    double ortalamaUretimSuresi = 0;
    int sureliModelSayisi = 0;
    for (var model in modeller) {
      if (model['tamamlandi'] == true && model['created_at'] != null) {
        final baslangic = DateTime.tryParse(model['created_at'].toString());
        final bitis = DateTime.tryParse(model['updated_at']?.toString() ?? '');
        if (baslangic != null && bitis != null) {
          ortalamaUretimSuresi += bitis.difference(baslangic).inDays;
          sureliModelSayisi++;
        }
      }
    }
    if (sureliModelSayisi > 0) {
      ortalamaUretimSuresi /= sureliModelSayisi;
    }

    return {
      'toplam_model': toplamModel,
      'tamamlanan': tamamlanan,
      'devam_eden': devamEden,
      'toplam_adet': toplamAdet,
      'toplam_fire': toplamFire,
      'asama_sayilari': asamaSayilari,
      'geciken_siparis': gecikenSiparis,
      'fire_analiz': fireAnaliz,
      'tedarikci_istatistik': tedarikciIstatistik,
      // KPI
      'verimlilik_orani': verimlilikOrani,
      'zamaninda_teslim_orani': zamanindaTeslimOrani,
      'fire_orani': fireOrani,
      'tamamlanma_orani': tamamlanmaOrani,
      'ortalama_uretim_suresi': ortalamaUretimSuresi,
    };
  }
}

/// Üretim raporu ham veri modeli
class UretimRaporuData {
  final List<Map<String, dynamic>> modeller;
  final List<String> markaListesi;
  final List<Map<String, dynamic>> tedarikciler;

  const UretimRaporuData({
    required this.modeller,
    required this.markaListesi,
    required this.tedarikciler,
  });
}

/// Filtreleme sonucu
class UretimRaporuFiltreSonuc {
  final List<Map<String, dynamic>> modeller;
  final Map<String, dynamic> ozet;

  const UretimRaporuFiltreSonuc({
    required this.modeller,
    required this.ozet,
  });
}
