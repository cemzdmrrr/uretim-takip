import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class GelismisRaporServisleri {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

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
      final personelQuery = _supabase.from(DbTables.personel).select('*').eq('firma_id', _firmaId).eq('aktif', true);
      final personeller = await personelQuery;

      final int toplamPersonel = personeller.length;
      final int aktifPersonel = personeller.where((p) => p['aktif'] == true).length;
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
        var mesaiQuery = _supabase.from(DbTables.mesaiKayitlari).select('*').eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          mesaiQuery = mesaiQuery.gte('tarih', baslangicTarihi.toIso8601String().split('T')[0]);
        }
        if (bitisTarihi != null) {
          mesaiQuery = mesaiQuery.lte('tarih', bitisTarihi.toIso8601String().split('T')[0]);
        }
        final mesailer = await mesaiQuery;

        for (var mesai in mesailer) {
          final saat = ((mesai['mesai_saati'] ?? mesai['toplam_saat'] ?? 0) as num).toDouble();
          toplamMesaiSaati += saat;
        }
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

      // İzin verilerini getir
      int toplamIzinGunu = 0;
      int kullanilanIzin = 0;
      try {
        var izinQuery = _supabase.from(DbTables.izinKayitlari).select('*').eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          izinQuery = izinQuery.gte('baslangic_tarihi', baslangicTarihi.toIso8601String().split('T')[0]);
        }
        if (bitisTarihi != null) {
          izinQuery = izinQuery.lte('bitis_tarihi', bitisTarihi.toIso8601String().split('T')[0]);
        }
        final izinler = await izinQuery;
        kullanilanIzin = izinler.length;
        for (var izin in izinler) {
          final gun = ((izin['gun_sayisi'] ?? 1) as num).toInt();
          toplamIzinGunu += gun;
        }
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

      // Departman bazlı sıralama
      final siraliDepartmanlar = departmanDagilimi.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'toplamPersonel': toplamPersonel,
        'aktifPersonel': aktifPersonel,
        'departmanDagilimi': Map.fromEntries(siraliDepartmanlar),
        'pozisyonDagilimi': pozisyonDagilimi,
        'toplamMesaiSaati': toplamMesaiSaati,
        'ortalamaMesaiSaati': toplamPersonel > 0 ? toplamMesaiSaati / toplamPersonel : 0,
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
          .select('toplam_adet, adet, yuklenen_adet, pesin_fiyat, iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat, ilik_dugme_fiyat, aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, created_at')
          .eq('firma_id', _firmaId)
          .gte('created_at', baslangic.toIso8601String());

      // Aylık bazda grupla
      final Map<String, Map<String, dynamic>> aylikVeriler = {};
      final ayIsimleri = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

      for (var model in modeller) {
        if (model['created_at'] == null) continue;
        try {
          final tarih = DateTime.parse(model['created_at']);
          final ayKey = '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}';
          final ayLabel = '${ayIsimleri[tarih.month - 1]} ${tarih.year}';

          aylikVeriler.putIfAbsent(ayKey, () => {
            'ayLabel': ayLabel,
            'siparisAdedi': 0,
            'toplamAdet': 0,
            'yuklenenAdet': 0,
            'toplamGelir': 0.0,
            'toplamMaliyet': 0.0,
            'modelSayisi': 0,
          });

          final adet = ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
          final yuklenenAdet = ((model['yuklenen_adet'] ?? 0) as num).toInt();
          final fiyat = ((model['pesin_fiyat'] ?? 0) as num).toDouble();
          final iplik = ((model['iplik_maliyeti'] ?? 0) as num).toDouble();
          final orgu = ((model['orgu_fiyat'] ?? 0) as num).toDouble();
          final dikim = ((model['dikim_fiyat'] ?? 0) as num).toDouble();
          final utu = ((model['utu_fiyat'] ?? 0) as num).toDouble();
          final yikama = ((model['yikama_fiyat'] ?? 0) as num).toDouble();
          final ilikDugme = ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
          final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelAksesuar = ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelGider = ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
          final birimMaliyet = iplik + orgu + dikim + utu + yikama + ilikDugme + aksesuar + genelAksesuar + genelGider;

          aylikVeriler[ayKey]!['modelSayisi'] = (aylikVeriler[ayKey]!['modelSayisi'] as int) + 1;
          aylikVeriler[ayKey]!['toplamAdet'] = (aylikVeriler[ayKey]!['toplamAdet'] as int) + adet;
          aylikVeriler[ayKey]!['yuklenenAdet'] = (aylikVeriler[ayKey]!['yuklenenAdet'] as int) + yuklenenAdet;
          // Gelir ve maliyet sadece yüklenen adet üzerinden hesaplanır
          aylikVeriler[ayKey]!['toplamGelir'] = (aylikVeriler[ayKey]!['toplamGelir'] as double) + (yuklenenAdet > 0 ? fiyat * yuklenenAdet : 0.0);
          aylikVeriler[ayKey]!['toplamMaliyet'] = (aylikVeriler[ayKey]!['toplamMaliyet'] as double) + (yuklenenAdet > 0 ? birimMaliyet * yuklenenAdet : 0.0);
        } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
      }

      // Kronolojik sırala
      final sirali = aylikVeriler.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Kar hesapla
      for (var entry in sirali) {
        final gelir = entry.value['toplamGelir'] as double;
        final maliyet = entry.value['toplamMaliyet'] as double;
        entry.value['kar'] = gelir - maliyet;
        entry.value['karMarji'] = gelir > 0 ? ((gelir - maliyet) / gelir) * 100 : 0.0;
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
  }) async {
    try {
      // Modelleri getir - gerçek veritabanı sütunları
      var query = _supabase.from(DbTables.trikoTakip).select('''
        id, marka, item_no, renk, adet, toplam_adet, yuklenen_adet, created_at, termin_tarihi,
        iplik_maliyeti, iplik_kg_fiyati, orgu_fiyat, dikim_fiyat, 
        utu_fiyat, yikama_fiyat, ilik_dugme_fiyat, aksesuar_fiyat,
        genel_aksesuar_fiyat, genel_gider_fiyat, kar_marji, pesin_fiyat
      ''').eq('firma_id', _firmaId);

      if (baslangicTarihi != null) {
        query = query.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('created_at', bitisTarihi.toIso8601String());
      }

      final modeller = await query;

      double toplamMaliyet = 0;
      double toplamIplikMaliyeti = 0;
      double toplamIscilikMaliyeti = 0;
      double toplamAksesuarMaliyeti = 0;
      double toplamGenelGider = 0;
      double toplamSatisFiyati = 0;
      int toplamAdet = 0;

      final List<Map<String, dynamic>> modelMaliyetleri = [];

      for (var model in modeller) {
        final adet = ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
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
        final genelAksesuar = ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
        final aksesuarToplam = aksesuar + genelAksesuar;
        
        // Genel gider
        final genelGider = ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
        
        // Satış fiyatı (peşin fiyat)
        final satis = ((model['pesin_fiyat'] ?? 0) as num).toDouble();
        
        // Birim maliyet hesapla
        final birimMaliyet = iplik + iscilikToplam + aksesuarToplam + genelGider;
        
        // Sadece yüklenen adet üzerinden hesapla - yükleme yoksa satış/maliyet yok
        final hesapAdet = yuklenenAdet > 0 ? yuklenenAdet : 0;
        final toplamModelMaliyet = birimMaliyet * hesapAdet;
        final toplamModelSatis = satis * hesapAdet;
        final kar = toplamModelSatis - toplamModelMaliyet;
        final karMarji = toplamModelSatis > 0 ? (kar / toplamModelSatis) * 100 : 0;

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
          'renk': model['renk'] ?? '',
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
      modelMaliyetleri.sort((a, b) => (b['kar'] as double).compareTo(a['kar'] as double));
      
      return {
        'modelMaliyetleri': modelMaliyetleri,
        'toplamMaliyet': toplamMaliyet,
        'toplamIplikMaliyeti': toplamIplikMaliyeti,
        'toplamAksesuarMaliyeti': toplamAksesuarMaliyeti,
        'toplamIscilikMaliyeti': toplamIscilikMaliyeti,
        'toplamGenelGider': toplamGenelGider,
        'toplamSatisFiyati': toplamSatisFiyati,
        'toplamAdet': toplamAdet,
        'toplamKar': toplamSatisFiyati - toplamMaliyet,
        'ortalamaKarMarji': toplamSatisFiyati > 0 
            ? ((toplamSatisFiyati - toplamMaliyet) / toplamSatisFiyati) * 100 
            : 0,
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
        'toplamIplikMaliyeti': 0.0,
        'toplamAksesuarMaliyeti': 0.0,
        'toplamIscilikMaliyeti': 0.0,
        'toplamGenelGider': 0.0,
        'toplamSatisFiyati': 0.0,
        'toplamAdet': 0,
        'toplamKar': 0.0,
        'ortalamaKarMarji': 0.0,
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

  /// Kâr/Zarar Analizi
  static Future<Map<String, dynamic>> getKarZararAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
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
    int faturaSayisi = 0;
    int hareketSayisi = 0;
    int depoSatisSayisi = 0;
    
    try {
      // 1. Fatura gelirlerini getir
      try {
        var faturaQuery = _supabase.from(DbTables.faturalar).select('*').eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          faturaQuery = faturaQuery.gte('fatura_tarihi', baslangicTarihi.toIso8601String().split('T')[0]);
        }
        if (bitisTarihi != null) {
          faturaQuery = faturaQuery.lte('fatura_tarihi', bitisTarihi.toIso8601String().split('T')[0]);
        }
        final faturalar = await faturaQuery;
        
        for (var fatura in faturalar) {
          final faturaTuru = fatura['fatura_turu']?.toString() ?? '';
          if (faturaTuru == 'satis' || faturaTuru == 'satış') {
            final tutar = ((fatura['toplam_tutar'] ?? fatura['tutar'] ?? 0) as num).toDouble();
            faturaGeliri += tutar;
            faturaSayisi++;
            
            final musteri = fatura['musteri_adi']?.toString() ?? fatura['musteri']?.toString() ?? 'Bilinmeyen';
            musteriBazliGelir[musteri] = (musteriBazliGelir[musteri] ?? 0) + tutar;
          }
        }
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

      // 2. Kasa/banka hareketlerini getir
      try {
        var hareketQuery = _supabase.from(DbTables.kasaBankaHareketleri).select('*').eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          hareketQuery = hareketQuery.gte('tarih', baslangicTarihi.toIso8601String().split('T')[0]);
        }
        if (bitisTarihi != null) {
          hareketQuery = hareketQuery.lte('tarih', bitisTarihi.toIso8601String().split('T')[0]);
        }
        final hareketler = await hareketQuery;
        hareketSayisi = hareketler.length;
        
        for (var hareket in hareketler) {
          final tutar = ((hareket['tutar'] ?? 0) as num).toDouble();
          final tip = hareket['islem_tipi']?.toString() ?? hareket['hareket_tipi']?.toString() ?? '';
          final kategori = hareket['kategori']?.toString() ?? hareket['aciklama']?.toString() ?? 'Diğer';
          
          if (tip == 'gelir' || tip == 'giris' || tip == 'tahsilat') {
            kasaGeliri += tutar;
            kategoriGelir[kategori] = (kategoriGelir[kategori] ?? 0) + tutar;
          } else if (tip == 'gider' || tip == 'cikis' || tip == 'odeme') {
            kasaGideri += tutar;
            kategoriGider[kategori] = (kategoriGider[kategori] ?? 0) + tutar;
          }
        }
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

      // 3. Ürün Depo Satışlarını getir
      try {
        final depoQuery = _supabase.from(DbTables.urunDepo).select('*').eq('firma_id', _firmaId);
        final depoVerileri = await depoQuery;
        
        for (var kayit in depoVerileri) {
          // satilan_tutar, satilan_adet veya benzeri sütunları kontrol et
          final satilanTutar = ((kayit['satilan_tutar'] ?? 0) as num).toDouble();
          final satilanAdet = ((kayit['satilan_adet'] ?? 0) as num).toInt();
          final birimFiyat = ((kayit['birim_fiyat'] ?? kayit['satis_fiyati'] ?? 0) as num).toDouble();
          
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
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

      // 4. Model bazlı gelir (triko_takip tablosundan satış fiyatları)
      double modelMaliyeti = 0; // Model üretim maliyetleri
      try {
        var modelQuery = _supabase.from(DbTables.trikoTakip).select('''
          marka, adet, toplam_adet, yuklenen_adet, pesin_fiyat, item_no,
          iplik_maliyeti, orgu_fiyat, dikim_fiyat, utu_fiyat, yikama_fiyat,
          ilik_dugme_fiyat, aksesuar_fiyat, genel_aksesuar_fiyat, genel_gider_fiyat, fermuar_fiyat
        ''').eq('firma_id', _firmaId);
        if (baslangicTarihi != null) {
          modelQuery = modelQuery.gte('created_at', baslangicTarihi.toIso8601String());
        }
        if (bitisTarihi != null) {
          modelQuery = modelQuery.lte('created_at', bitisTarihi.toIso8601String());
        }
        final modeller = await modelQuery;
        
        double modelSatisGeliri = 0;
        for (var model in modeller) {
          final adet = ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
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
          final ilikDugme = ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
          final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelAksesuar = ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
          final genelGider = ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
          final fermuar = ((model['fermuar_fiyat'] ?? 0) as num).toDouble();
          
          final birimMaliyet = iplik + orgu + dikim + utu + yikama + ilikDugme + aksesuar + genelAksesuar + genelGider + fermuar;
          modelMaliyeti += birimMaliyet * hesapAdet;
          
          if (hesapAdet > 0) {
            final marka = model['marka']?.toString() ?? 'Diğer';
            musteriBazliGelir[marka] = (musteriBazliGelir[marka] ?? 0) + (hesapAdet * fiyat);
          }
        }
        
        // Model maliyetlerini kategori giderine ekle
        if (modelMaliyeti > 0) {
          kategoriGider['Üretim Maliyeti'] = (kategoriGider['Üretim Maliyeti'] ?? 0) + modelMaliyeti;
        }

        
        // Model satış gelirini kategori gelirine ekle
        if (modelSatisGeliri > 0) {
          kategoriGelir['Satış'] = (kategoriGelir['Satış'] ?? 0) + modelSatisGeliri;
        }

        
        // Eğer fatura geliri yoksa model satış gelirini kullan
        if (faturaGeliri == 0) {
          faturaGeliri = modelSatisGeliri;
        }
      } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }

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
      final tedarikciler = await _supabase.from(DbTables.tedarikciler).select('*').eq('firma_id', _firmaId);

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
          final query = _supabase
              .from(atamaTablosu)
              .select('id, durum, atama_tarihi, tamamlama_tarihi')
              .eq('tedarikci_id', tedarikciId);

          final atamalar = await query;

          final int toplamAtama = atamalar.length;
          final int tamamlanan = atamalar.where((a) => a['durum'] == 'tamamlandi').length;
          final int devamEden = atamalar.where((a) => a['durum'] == 'uretimde' || a['durum'] == 'onaylandi').length;
          final int bekleyen = atamalar.where((a) => a['durum'] == 'atandi' || a['durum'] == null).length;
          
          // Ortalama tamamlama süresi
          double toplamSure = 0;
          int sureliAtama = 0;
          for (var atama in atamalar) {
            if (atama['atama_tarihi'] != null && atama['tamamlama_tarihi'] != null) {
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
            'tamamlanmaOrani': toplamAtama > 0 ? (tamamlanan / toplamAtama) * 100 : 0,
            'ortalamaTamamlamaSuresi': ortalamaSure,
          });
        } catch (e) {
          // Tablo yoksa atla
          continue;
        }
      }

      // Performansa göre sırala
      tedarikciPerformanslari.sort((a, b) => 
          (b['tamamlanmaOrani'] as double).compareTo(a['tamamlanmaOrani'] as double));

      return {
        'tedarikciPerformanslari': tedarikciPerformanslari,
        'toplamTedarikci': tedarikciPerformanslari.length,
        'ortalamaPerformans': tedarikciPerformanslari.isNotEmpty
            ? tedarikciPerformanslari.fold(0.0, (sum, t) => sum + (t['tamamlanmaOrani'] as double)) / tedarikciPerformanslari.length
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
          final response = await _supabase
              .from(tablo)
              .select('id, durum, atama_tarihi, tamamlama_tarihi, tamamlanan_adet');

          final asamaAdi = tablo.replaceAll('_atamalari', '').replaceAll('_', ' ').capitalize();
          
          final int toplam = response.length;
          final int tamamlanan = response.where((r) => r['durum'] == 'tamamlandi').length;
          final int uretimde = response.where((r) => r['durum'] == 'uretimde').length;
          final int bekleyen = response.where((r) => r['durum'] == 'atandi' || r['durum'] == null).length;
          final int tamamlananAdet = response.fold(0, (sum, r) => sum + ((r['tamamlanan_adet'] ?? 0) as int));

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
      final int toplamIs = asamaVerileri.values.fold(0, (sum, v) => sum + (v['toplam'] as int));
      final int toplamTamamlanan = asamaVerileri.values.fold(0, (sum, v) => sum + (v['tamamlanan'] as int));
      final double genelVerimlilik = toplamIs > 0 ? (toplamTamamlanan / toplamIs) * 100 : 0;

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
  }) async {
    try {
      var query = _supabase.from(DbTables.trikoTakip).select('*').eq('firma_id', _firmaId);
      
      if (baslangicTarihi != null) {
        query = query.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('created_at', bitisTarihi.toIso8601String());
      }

      final modeller = await query;

      final Map<String, Map<String, dynamic>> markaVerileri = {};
      
      for (var model in modeller) {
        final marka = model['marka'] ?? 'Bilinmeyen';
        final adet = ((model['toplam_adet'] ?? model['adet'] ?? 0) as num).toInt();
        final yuklenenAdet = ((model['yuklenen_adet'] ?? 0) as num).toInt();
        // pesin_fiyat kullan (satis_fiyati yerine)
        final satisFiyati = ((model['pesin_fiyat'] ?? model['satis_fiyati'] ?? 0) as num).toDouble();
        // Birim maliyet hesapla
        final iplik = ((model['iplik_maliyeti'] ?? 0) as num).toDouble();
        final orgu = ((model['orgu_fiyat'] ?? 0) as num).toDouble();
        final dikim = ((model['dikim_fiyat'] ?? 0) as num).toDouble();
        final utu = ((model['utu_fiyat'] ?? 0) as num).toDouble();
        final yikama = ((model['yikama_fiyat'] ?? 0) as num).toDouble();
        final ilikDugme = ((model['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
        final aksesuar = ((model['aksesuar_fiyat'] ?? 0) as num).toDouble();
        final genelAksesuar = ((model['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
        final genelGider = ((model['genel_gider_fiyat'] ?? 0) as num).toDouble();
        final birimMaliyet = iplik + orgu + dikim + utu + yikama + ilikDugme + aksesuar + genelAksesuar + genelGider;

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

        markaVerileri[marka]!['modelSayisi'] = (markaVerileri[marka]!['modelSayisi'] as int) + 1;
        markaVerileri[marka]!['toplamAdet'] = (markaVerileri[marka]!['toplamAdet'] as int) + adet;
        markaVerileri[marka]!['yuklenenAdet'] = (markaVerileri[marka]!['yuklenenAdet'] as int) + yuklenenAdet;
        markaVerileri[marka]!['toplamSatis'] = (markaVerileri[marka]!['toplamSatis'] as double) + (satisFiyati * hesapAdet);
        markaVerileri[marka]!['toplamMaliyet'] = (markaVerileri[marka]!['toplamMaliyet'] as double) + (birimMaliyet * hesapAdet);
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
        ..sort((a, b) => (b.value['toplamAdet'] as int).compareTo(a.value['toplamAdet'] as int));

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
