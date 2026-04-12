import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Gelismis rapor servisleri - operasyonel analizler (termin, stok, sevkiyat, kalite)
class GelismisRaporOperasyonServisleri {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;
  static Future<Map<String, dynamic>> getTerminTakipAnalizi() async {
    try {
      final modeller = await _supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, adet, toplam_adet, termin_tarihi, created_at')
          .eq('firma_id', _firmaId)
          .not('termin_tarihi', 'is', null);

      final now = DateTime.now();
      final List<Map<String, dynamic>> gecikmisSiparisler = [];
      final List<Map<String, dynamic>> bugunTermin = [];
      final List<Map<String, dynamic>> yaklasanTerminler = [];
      final List<Map<String, dynamic>> normalTerminler = [];

      for (var model in modeller) {
        final terminStr = model['termin_tarihi'];
        if (terminStr == null) continue;

        DateTime termin;
        try {
          termin = DateTime.parse(terminStr);
        } catch (e) {
          continue;
        }

        final fark = termin.difference(now).inDays;
        final modelData = {
          'id': model['id'],
          'marka': model['marka'] ?? '',
          'itemNo': model['item_no'] ?? '',
          'renk': model['renk'] ?? '',
          'adet': model['toplam_adet'] ?? model['adet'] ?? 0,
          'terminTarihi': terminStr,
          'kalanGun': fark,
        };

        if (fark < 0) {
          gecikmisSiparisler.add(modelData);
        } else if (fark == 0) {
          bugunTermin.add(modelData);
        } else if (fark <= 7) {
          yaklasanTerminler.add(modelData);
        } else {
          normalTerminler.add(modelData);
        }
      }

      // Gecikme süresine göre sırala
      gecikmisSiparisler.sort((a, b) => (a['kalanGun'] as int).compareTo(b['kalanGun'] as int));
      yaklasanTerminler.sort((a, b) => (a['kalanGun'] as int).compareTo(b['kalanGun'] as int));

      return {
        'gecikmisSiparisler': gecikmisSiparisler,
        'bugunTermin': bugunTermin,
        'yaklasanTerminler': yaklasanTerminler,
        'normalTerminler': normalTerminler,
        'toplamGeciken': gecikmisSiparisler.length,
        'toplamBugun': bugunTermin.length,
        'toplamYaklasan': yaklasanTerminler.length,
        'toplamNormal': normalTerminler.length,
        'gecikmeOrani': modeller.isNotEmpty 
            ? (gecikmisSiparisler.length / modeller.length) * 100 
            : 0,
      };
    } catch (e) {
      return {
        'gecikmisSiparisler': <Map<String, dynamic>>[],
        'bugunTermin': <Map<String, dynamic>>[],
        'yaklasanTerminler': <Map<String, dynamic>>[],
        'normalTerminler': <Map<String, dynamic>>[],
        'toplamGeciken': 0,
        'toplamBugun': 0,
        'toplamYaklasan': 0,
        'toplamNormal': 0,
        'gecikmeOrani': 0.0,
        'hata': e.toString(),
      };
    }
  }

  // Demo veri metotları kaldırıldı - artık gerçek boş veri döndürülüyor

  // ==============================================
  // STOK RAPORLARI
  // ==============================================

  /// İplik ve Aksesuar Stok Analizi
  static Future<Map<String, dynamic>> getStokAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      // İplik stoklarını getir
      final iplikStoklar = await _supabase.from(DbTables.iplikStoklari).select('*').eq('firma_id', _firmaId);
      
      // İplik hareketlerini getir
      var hareketQuery = _supabase.from(DbTables.iplikHareketleri).select('*').eq('firma_id', _firmaId);
      if (baslangicTarihi != null) {
        hareketQuery = hareketQuery.gte('tarih', baslangicTarihi.toIso8601String().split('T')[0]);
      }
      if (bitisTarihi != null) {
        hareketQuery = hareketQuery.lte('tarih', bitisTarihi.toIso8601String().split('T')[0]);
      }
      final iplikHareketler = await hareketQuery;

      // Aksesuar stoklarını getir
      List<dynamic> aksesuarlar = [];
      try {
        aksesuarlar = await _supabase.from(DbTables.aksesuarlar).select('*').eq('firma_id', _firmaId);
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

      // İplik stok analizi
      double toplamIplikDeger = 0;
      double toplamIplikMiktar = 0;
      final Map<String, double> iplikTipiDagilim = {};
      final Map<String, double> tedarikciBazliStok = {};
      
      for (var stok in iplikStoklar) {
        final miktar = ((stok['miktar'] ?? stok['stok_miktari'] ?? 0) as num).toDouble();
        final birimFiyat = ((stok['birim_fiyat'] ?? stok['fiyat'] ?? 0) as num).toDouble();
        final deger = miktar * birimFiyat;
        
        toplamIplikMiktar += miktar;
        toplamIplikDeger += deger;
        
        final tip = stok['iplik_tipi'] ?? stok['tur'] ?? 'Diğer';
        iplikTipiDagilim[tip] = (iplikTipiDagilim[tip] ?? 0) + miktar;
        
        final tedarikci = stok['tedarikci'] ?? stok['tedarikci_adi'] ?? 'Bilinmeyen';
        tedarikciBazliStok[tedarikci] = (tedarikciBazliStok[tedarikci] ?? 0) + deger;
      }

      // İplik hareketleri analizi (tüketim)
      double toplamGiris = 0;
      double toplamCikis = 0;
      final Map<String, double> aylikTuketim = {};
      
      for (var hareket in iplikHareketler) {
        final miktar = ((hareket['miktar'] ?? 0) as num).toDouble();
        final tip = hareket['hareket_tipi'] ?? hareket['islem_tipi'] ?? '';
        
        if (tip == 'giris' || tip == 'alis') {
          toplamGiris += miktar;
        } else if (tip == 'cikis' || tip == 'kullanim' || tip == 'uretim') {
          toplamCikis += miktar;
        }
        
        // Aylık tüketim
        final tarihStr = hareket['tarih'] ?? hareket['created_at'];
        if (tarihStr != null && (tip == 'cikis' || tip == 'kullanim' || tip == 'uretim')) {
          try {
            final tarih = DateTime.parse(tarihStr);
            final ayKey = DateFormat('yyyy-MM').format(tarih);
            aylikTuketim[ayKey] = (aylikTuketim[ayKey] ?? 0) + miktar;
          } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
        }
      }

      // Aksesuar stok analizi
      double toplamAksesuarDeger = 0;
      final int toplamAksesuarCesit = aksesuarlar.length;
      final Map<String, int> aksesuarKategori = {};
      
      for (var aksesuar in aksesuarlar) {
        final miktar = ((aksesuar['miktar'] ?? aksesuar['stok'] ?? 0) as num).toDouble();
        final birimFiyat = ((aksesuar['birim_fiyat'] ?? aksesuar['fiyat'] ?? 0) as num).toDouble();
        toplamAksesuarDeger += miktar * birimFiyat;
        
        final kategori = aksesuar['kategori'] ?? aksesuar['tur'] ?? 'Diğer';
        aksesuarKategori[kategori] = (aksesuarKategori[kategori] ?? 0) + 1;
      }

      // Stok devir hızı (son 30 günlük ortalama tüketim)
      final ortalamaGunlukTuketim = toplamCikis / 30;
      final stokDevirSuresi = ortalamaGunlukTuketim > 0 ? toplamIplikMiktar / ortalamaGunlukTuketim : 0;

      return {
        'iplikStok': {
          'toplamMiktar': toplamIplikMiktar,
          'toplamDeger': toplamIplikDeger,
          'tipDagilimi': iplikTipiDagilim,
          'tedarikciBazli': tedarikciBazliStok,
          'stokSayisi': iplikStoklar.length,
        },
        'iplikHareket': {
          'toplamGiris': toplamGiris,
          'toplamCikis': toplamCikis,
          'aylikTuketim': aylikTuketim,
          'ortalamaGunlukTuketim': ortalamaGunlukTuketim,
          'stokDevirSuresi': stokDevirSuresi,
        },
        'aksesuarStok': {
          'toplamDeger': toplamAksesuarDeger,
          'cesitSayisi': toplamAksesuarCesit,
          'kategoriDagilimi': aksesuarKategori,
        },
        'toplamStokDeger': toplamIplikDeger + toplamAksesuarDeger,
      };
    } catch (e) {
      return {
        'iplikStok': {'toplamMiktar': 0.0, 'toplamDeger': 0.0, 'tipDagilimi': <String, double>{}, 'tedarikciBazli': <String, double>{}, 'stokSayisi': 0},
        'iplikHareket': {'toplamGiris': 0.0, 'toplamCikis': 0.0, 'aylikTuketim': <String, double>{}, 'ortalamaGunlukTuketim': 0.0, 'stokDevirSuresi': 0.0},
        'aksesuarStok': {'toplamDeger': 0.0, 'cesitSayisi': 0, 'kategoriDagilimi': <String, int>{}},
        'toplamStokDeger': 0.0,
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // SEVKİYAT RAPORLARI
  // ==============================================

  /// Sevkiyat Performans Analizi
  static Future<Map<String, dynamic>> getSevkiyatAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      // Sevkiyat kayıtlarını getir
      var sevkQuery = _supabase.from(DbTables.sevkiyatKayitlari).select('*').eq('firma_id', _firmaId);
      if (baslangicTarihi != null) {
        sevkQuery = sevkQuery.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        sevkQuery = sevkQuery.lte('created_at', bitisTarihi.toIso8601String());
      }
      final sevkiyatlar = await sevkQuery;

      // Sevk taleplerini getir
      var talepQuery = _supabase.from(DbTables.sevkTalepleri).select('*').eq('firma_id', _firmaId);
      if (baslangicTarihi != null) {
        talepQuery = talepQuery.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        talepQuery = talepQuery.lte('created_at', bitisTarihi.toIso8601String());
      }
      final talepler = await talepQuery;

      final int toplamSevkiyat = sevkiyatlar.length;
      int tamamlananSevkiyat = 0;
      int gecikanSevkiyat = 0;
      int bekleyenSevkiyat = 0;
      int zamanindaTeslim = 0;
      double toplamSevkAdet = 0;
      final Map<String, int> musteriBazliSevk = {};
      final Map<String, int> aylikSevkiyat = {};
      final List<Map<String, dynamic>> gecikanler = [];

      for (var sevk in sevkiyatlar) {
        final durum = sevk['durum'] ?? '';
        final adet = ((sevk['adet'] ?? sevk['miktar'] ?? 0) as num).toInt();
        toplamSevkAdet += adet;
        
        if (durum == 'tamamlandi' || durum == 'teslim_edildi') {
          tamamlananSevkiyat++;
          
          // Zamanında teslim kontrolü
          final planliTarihStr = sevk['planlanan_tarih'] ?? sevk['termin_tarihi'];
          final teslimTarihStr = sevk['teslim_tarihi'] ?? sevk['tamamlanma_tarihi'];
          
          if (planliTarihStr != null && teslimTarihStr != null) {
            try {
              final planli = DateTime.parse(planliTarihStr);
              final teslim = DateTime.parse(teslimTarihStr);
              if (!teslim.isAfter(planli)) {
                zamanindaTeslim++;
              }
            } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
          }
        } else if (durum == 'beklemede' || durum == 'hazirlaniyor') {
          bekleyenSevkiyat++;
        }
        
        // Gecikme kontrolü
        final planliTarihStr = sevk['planlanan_tarih'] ?? sevk['termin_tarihi'];
        if (planliTarihStr != null && durum != 'tamamlandi' && durum != 'teslim_edildi') {
          try {
            final planli = DateTime.parse(planliTarihStr);
            if (planli.isBefore(DateTime.now())) {
              gecikanSevkiyat++;
              gecikanler.add({
                'id': sevk['id'],
                'musteri': sevk['musteri_adi'] ?? sevk['musteri'] ?? '',
                'planliTarih': planliTarihStr,
                'gecikmeGun': DateTime.now().difference(planli).inDays,
              });
            }
          } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
        }
        
        // Müşteri bazlı
        final musteri = sevk['musteri_adi'] ?? sevk['musteri'] ?? 'Bilinmeyen';
        musteriBazliSevk[musteri] = (musteriBazliSevk[musteri] ?? 0) + 1;
        
        // Aylık sevkiyat
        final tarihStr = sevk['created_at'];
        if (tarihStr != null) {
          try {
            final tarih = DateTime.parse(tarihStr);
            final ayKey = DateFormat('yyyy-MM').format(tarih);
            aylikSevkiyat[ayKey] = (aylikSevkiyat[ayKey] ?? 0) + 1;
          } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
        }
      }

      // Talep analizi
      final int toplamTalep = talepler.length;
      final int onaylananTalep = talepler.where((t) => t['durum'] == 'onaylandi').length;
      final int bekleyenTalep = talepler.where((t) => t['durum'] == 'beklemede' || t['durum'] == null).length;

      final zamanindaOrani = tamamlananSevkiyat > 0 ? (zamanindaTeslim / tamamlananSevkiyat) * 100 : 0;
      final tamamlanmaOrani = toplamSevkiyat > 0 ? (tamamlananSevkiyat / toplamSevkiyat) * 100 : 0;

      return {
        'toplamSevkiyat': toplamSevkiyat,
        'tamamlananSevkiyat': tamamlananSevkiyat,
        'bekleyenSevkiyat': bekleyenSevkiyat,
        'gecikanSevkiyat': gecikanSevkiyat,
        'zamanindaTeslim': zamanindaTeslim,
        'zamanindaOrani': zamanindaOrani,
        'tamamlanmaOrani': tamamlanmaOrani,
        'toplamSevkAdet': toplamSevkAdet,
        'musteriBazliSevk': musteriBazliSevk,
        'aylikSevkiyat': aylikSevkiyat,
        'gecikanler': gecikanler,
        'talepAnalizi': {
          'toplamTalep': toplamTalep,
          'onaylanan': onaylananTalep,
          'bekleyen': bekleyenTalep,
        },
      };
    } catch (e) {
      return {
        'toplamSevkiyat': 0,
        'tamamlananSevkiyat': 0,
        'bekleyenSevkiyat': 0,
        'gecikanSevkiyat': 0,
        'zamanindaTeslim': 0,
        'zamanindaOrani': 0.0,
        'tamamlanmaOrani': 0.0,
        'toplamSevkAdet': 0.0,
        'musteriBazliSevk': <String, int>{},
        'aylikSevkiyat': <String, int>{},
        'gecikanler': <Map<String, dynamic>>[],
        'talepAnalizi': {'toplamTalep': 0, 'onaylanan': 0, 'bekleyen': 0},
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // KALİTE RAPORLARI
  // ==============================================

  /// Kalite Kontrol Analizi
  static Future<Map<String, dynamic>> getKaliteAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      // Kalite kontrol atamalarını getir
      var kaliteQuery = _supabase.from(DbTables.kaliteKontrolAtamalari).select('*').eq('firma_id', _firmaId);
      if (baslangicTarihi != null) {
        kaliteQuery = kaliteQuery.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        kaliteQuery = kaliteQuery.lte('created_at', bitisTarihi.toIso8601String());
      }
      final kaliteKontroller = await kaliteQuery;

      // Ürün depo verilerini kalite analizi için getir
      final depoUrunler = await _supabase.from(DbTables.urunDepo).select('*').eq('firma_id', _firmaId);

      final int toplamKontrol = kaliteKontroller.length;
      int basariliKontrol = 0;
      int basarisizKontrol = 0;
      int bekleyenKontrol = 0;
      double toplamFireAdet = 0;
      double toplamKontrolAdet = 0;
      final Map<String, int> hataTipiDagilimi = {};
      final Map<String, double> modelBazliFire = {};
      final List<Map<String, dynamic>> sorunluModeller = [];

      for (var kontrol in kaliteKontroller) {
        final durum = kontrol['durum'] ?? '';
        final kontrolAdet = ((kontrol['kontrol_adet'] ?? kontrol['adet'] ?? 0) as num).toDouble();
        final fireAdet = ((kontrol['fire_adet'] ?? kontrol['hatali_adet'] ?? 0) as num).toDouble();
        
        toplamKontrolAdet += kontrolAdet;
        toplamFireAdet += fireAdet;
        
        if (durum == 'onaylandi' || durum == 'basarili' || durum == 'tamamlandi') {
          basariliKontrol++;
        } else if (durum == 'reddedildi' || durum == 'basarisiz') {
          basarisizKontrol++;
        } else {
          bekleyenKontrol++;
        }
        
        // Hata tipi
        final hataTipi = kontrol['hata_tipi'] ?? kontrol['red_sebebi'] ?? '';
        if (hataTipi.toString().isNotEmpty) {
          hataTipiDagilimi[hataTipi] = (hataTipiDagilimi[hataTipi] ?? 0) + 1;
        }
        
        // Model bazlı fire
        final modelId = kontrol['model_id']?.toString() ?? '';
        if (modelId.isNotEmpty && fireAdet > 0) {
          modelBazliFire[modelId] = (modelBazliFire[modelId] ?? 0) + fireAdet;
          
          if (fireAdet > 10) {
            sorunluModeller.add({
              'modelId': modelId,
              'fireAdet': fireAdet,
              'kontrolAdet': kontrolAdet,
              'fireOrani': kontrolAdet > 0 ? (fireAdet / kontrolAdet) * 100 : 0,
            });
          }
        }
      }

      // Depo kalite dağılımı
      int birinciKalite = 0;
      int ikinciKalite = 0;
      double birinciKaliteAdet = 0;
      double ikinciKaliteAdet = 0;
      
      for (var urun in depoUrunler) {
        final kaliteTipi = urun['kalite_tipi'] ?? '';
        final adet = ((urun['adet'] ?? 0) as num).toDouble();
        
        if (kaliteTipi.toString().contains('1.')) {
          birinciKalite++;
          birinciKaliteAdet += adet;
        } else if (kaliteTipi.toString().contains('2.') || kaliteTipi.toString().contains('3.')) {
          ikinciKalite++;
          ikinciKaliteAdet += adet;
        }
      }

      final fireOrani = toplamKontrolAdet > 0 ? (toplamFireAdet / toplamKontrolAdet) * 100 : 0;
      final basariOrani = toplamKontrol > 0 ? (basariliKontrol / toplamKontrol) * 100 : 0;
      final birinciKaliteOrani = (birinciKaliteAdet + ikinciKaliteAdet) > 0 
          ? (birinciKaliteAdet / (birinciKaliteAdet + ikinciKaliteAdet)) * 100 
          : 0;

      // Sorunlu modelleri fire oranına göre sırala
      sorunluModeller.sort((a, b) => (b['fireOrani'] as double).compareTo(a['fireOrani'] as double));

      return {
        'toplamKontrol': toplamKontrol,
        'basariliKontrol': basariliKontrol,
        'basarisizKontrol': basarisizKontrol,
        'bekleyenKontrol': bekleyenKontrol,
        'basariOrani': basariOrani,
        'fireAnalizi': {
          'toplamFireAdet': toplamFireAdet,
          'toplamKontrolAdet': toplamKontrolAdet,
          'fireOrani': fireOrani,
          'hataTipiDagilimi': hataTipiDagilimi,
          'modelBazliFire': modelBazliFire,
        },
        'kaliteDagilimi': {
          'birinciKaliteSayisi': birinciKalite,
          'ikinciKaliteSayisi': ikinciKalite,
          'birinciKaliteAdet': birinciKaliteAdet,
          'ikinciKaliteAdet': ikinciKaliteAdet,
          'birinciKaliteOrani': birinciKaliteOrani,
        },
        'sorunluModeller': sorunluModeller.take(10).toList(),
      };
    } catch (e) {
      return {
        'toplamKontrol': 0,
        'basariliKontrol': 0,
        'basarisizKontrol': 0,
        'bekleyenKontrol': 0,
        'basariOrani': 0.0,
        'fireAnalizi': {'toplamFireAdet': 0.0, 'toplamKontrolAdet': 0.0, 'fireOrani': 0.0, 'hataTipiDagilimi': <String, int>{}, 'modelBazliFire': <String, double>{}},
        'kaliteDagilimi': {'birinciKaliteSayisi': 0, 'ikinciKaliteSayisi': 0, 'birinciKaliteAdet': 0.0, 'ikinciKaliteAdet': 0.0, 'birinciKaliteOrani': 0.0},
        'sorunluModeller': <Map<String, dynamic>>[],
        'hata': e.toString(),
      };
    }
  }

  // Demo veri metotları kaldırıldı
}

// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
