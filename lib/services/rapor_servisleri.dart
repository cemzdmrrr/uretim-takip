import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class RaporServisleri {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // ==============================================
  // ÜRETİM RAPORLARI
  // ==============================================

  /// Üretim aşaması bazlı süre analizleri
  static Future<Map<String, dynamic>> getUretimAsasmaSureAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? modelAdi,
  }) async {
    try {
      var query = _supabase
          .from(DbTables.uretimKayitlari)
          .select('*')
          .eq('firma_id', _firmaId);

      if (baslangicTarihi != null) {
        query = query.gte('baslangic_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('bitis_tarihi', bitisTarihi.toIso8601String());
      }
      
      final response = await query;
      
      // Aşama bazlı ortalama süreler
      final Map<String, List<int>> asamaSureleri = {};
      final Map<String, int> asamaSayilari = {};
      
      for (final kayit in response) {
        final asama = kayit['asama_adi']?.toString() ?? 'Bilinmeyen';
        final baslangic = kayit['baslangic_tarihi'];
        final bitis = kayit['bitis_tarihi'];
        
        if (baslangic != null && bitis != null) {
          final sure = DateTime.parse(bitis).difference(DateTime.parse(baslangic)).inHours;
          asamaSureleri.putIfAbsent(asama, () => []).add(sure);
          asamaSayilari[asama] = (asamaSayilari[asama] ?? 0) + 1;
        }
      }

      // Ortalama hesaplama
      final Map<String, double> ortalamaAsasmaSureleri = {};
      asamaSureleri.forEach((asama, sureler) {
        if (sureler.isNotEmpty) {
          ortalamaAsasmaSureleri[asama] = sureler.reduce((a, b) => a + b) / sureler.length;
        }
      });

      return {
        'ortalamaAsasmaSureleri': ortalamaAsasmaSureleri,
        'asamaSayilari': asamaSayilari,
        'toplamKayit': response.length,
        'hamVeri': response,
      };
    } catch (e) {
      return {
        'ortalamaAsasmaSureleri': <String, double>{},
        'asamaSayilari': <String, int>{},
        'toplamKayit': 0,
        'hamVeri': <Map<String, dynamic>>[],
        'hata': e.toString(),
      };
    }
  }

  /// Model bazlı üretim performansı
  static Future<Map<String, dynamic>> getModelUretimPerformansi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
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

      final response = await query;
      
      final List<Map<String, dynamic>> modelPerformanslari = [];
      
      for (final model in response) {
        modelPerformanslari.add({
          'modelAdi': model['item_no'] ?? model['model_adi'] ?? 'Bilinmeyen',
          'musteriAdi': model['marka'] ?? 'Bilinmeyen',
          'siparisAdeti': model['toplam_adet'] ?? model['adet'] ?? 0,
          'tamamlandi': model['tamamlandi'] ?? false,
        });
      }

      return {
        'modelPerformanslari': modelPerformanslari,
        'toplamModel': modelPerformanslari.length,
      };
    } catch (e) {
      return {
        'modelPerformanslari': <Map<String, dynamic>>[],
        'toplamModel': 0,
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // SİPARİŞ RAPORLARI
  // ==============================================

  /// Sipariş durum analizi
  static Future<Map<String, dynamic>> getSiparisDurumAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? musteriAdi,
  }) async {
    try {
      var query = _supabase.from(DbTables.trikoTakip).select('*').eq('firma_id', _firmaId);

      if (baslangicTarihi != null) {
        query = query.gte('created_at', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('created_at', bitisTarihi.toIso8601String());
      }
      if (musteriAdi != null && musteriAdi != 'Tümü') {
        query = query.eq('marka', musteriAdi);
      }

      final response = await query;
      
      // Durum bazlı sayılar
      final Map<String, int> durumSayilari = {};
      final Map<String, List<int>> durumAdedleri = {};
      double toplamSiparisAdedi = 0;
      
      for (final siparis in response) {
        final durum = siparis['durum']?.toString() ?? 'Bilinmeyen';
        final adet = (siparis['toplam_adet'] ?? siparis['adet'] ?? 0) as int;
        
        durumSayilari[durum] = (durumSayilari[durum] ?? 0) + 1;
        durumAdedleri.putIfAbsent(durum, () => []).add(adet);
        toplamSiparisAdedi += adet;
      }

      return {
        'durumSayilari': durumSayilari,
        'durumAdedleri': durumAdedleri,
        'toplamSiparis': response.length,
        'toplamSiparisAdedi': toplamSiparisAdedi,
        'hamVeri': response,
      };
    } catch (e) {
      return {
        'durumSayilari': <String, int>{},
        'durumAdedleri': <String, List<int>>{},
        'toplamSiparis': 0,
        'toplamSiparisAdedi': 0.0,
        'hamVeri': <Map<String, dynamic>>[],
        'hata': e.toString(),
      };
    }
  }

  /// Müşteri bazlı sipariş analizi
  static Future<Map<String, dynamic>> getMusteriSiparisAnalizi({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    var query = _supabase.from(DbTables.trikoTakip).select('*').eq('firma_id', _firmaId);

    if (baslangicTarihi != null) {
      query = query.gte('created_at', baslangicTarihi.toIso8601String());
    }
    if (bitisTarihi != null) {
      query = query.lte('created_at', bitisTarihi.toIso8601String());
    }

    final response = await query;
    
    final Map<String, Map<String, dynamic>> musteriAnalizleri = {};
    
    for (final siparis in response) {
      final musteri = siparis['marka']?.toString() ?? 'Bilinmeyen';
      final adet = (siparis['toplam_adet'] ?? siparis['adet'] ?? 0) as int;
      final durum = siparis['durum']?.toString() ?? 'Bilinmeyen';
      
      if (!musteriAnalizleri.containsKey(musteri)) {
        musteriAnalizleri[musteri] = {
          'toplamSiparis': 0,
          'toplamAdet': 0,
          'tamamlanan': 0,
          'devamEden': 0,
          'bekleyen': 0,
        };
      }
      
      musteriAnalizleri[musteri]!['toplamSiparis'] = 
          (musteriAnalizleri[musteri]!['toplamSiparis'] as int) + 1;
      musteriAnalizleri[musteri]!['toplamAdet'] = 
          (musteriAnalizleri[musteri]!['toplamAdet'] as int) + adet;
          
      switch (durum) {
        case 'tamamlandi':
          musteriAnalizleri[musteri]!['tamamlanan'] = 
              (musteriAnalizleri[musteri]!['tamamlanan'] as int) + 1;
          break;
        case 'devam_ediyor':
          musteriAnalizleri[musteri]!['devamEden'] = 
              (musteriAnalizleri[musteri]!['devamEden'] as int) + 1;
          break;
        default:
          musteriAnalizleri[musteri]!['bekleyen'] = 
              (musteriAnalizleri[musteri]!['bekleyen'] as int) + 1;
      }
    }

    return {
      'musteriAnalizleri': musteriAnalizleri,
      'toplamMusteri': musteriAnalizleri.length,
      'hamVeri': response,
    };
  }

  // ==============================================
  // STOK RAPORLARI
  // ==============================================

  /// Stok seviye analizi
  static Future<Map<String, dynamic>> getStokSeviyeAnalizi() async {
    try {
      final response = await _supabase
          .from(DbTables.stokHareketleri)
          .select('*')
          .eq('firma_id', _firmaId)
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> stokDurumlari = {};
      
      for (final hareket in response) {
        final urunAdi = hareket['urun_adi']?.toString() ?? 'Bilinmeyen';
        final hareketTipi = hareket['hareket_tipi']?.toString() ?? '';
        final miktar = hareket['miktar'] as int? ?? 0;
        
        if (!stokDurumlari.containsKey(urunAdi)) {
          stokDurumlari[urunAdi] = {
            'mevcutStok': 0,
            'toplamGiris': 0,
            'toplamCikis': 0,
            'sonHareketTarihi': hareket['created_at'],
          };
        }
        
        if (hareketTipi == 'giris') {
          stokDurumlari[urunAdi]!['mevcutStok'] = 
              (stokDurumlari[urunAdi]!['mevcutStok'] as int) + miktar;
          stokDurumlari[urunAdi]!['toplamGiris'] = 
              (stokDurumlari[urunAdi]!['toplamGiris'] as int) + miktar;
        } else if (hareketTipi == 'cikis') {
          stokDurumlari[urunAdi]!['mevcutStok'] = 
              (stokDurumlari[urunAdi]!['mevcutStok'] as int) - miktar;
          stokDurumlari[urunAdi]!['toplamCikis'] = 
              (stokDurumlari[urunAdi]!['toplamCikis'] as int) + miktar;
        }
      }

      // Kritik stok seviyelerini belirle
      final List<Map<String, dynamic>> kritikStoklar = [];
      stokDurumlari.forEach((urun, durum) {
        if ((durum['mevcutStok'] as int) < 10) { // Kritik seviye: 10
          kritikStoklar.add({
            'urunAdi': urun,
            'mevcutStok': durum['mevcutStok'],
            'kritikSeviye': 10,
          });
        }
      });

      return {
        'stokDurumlari': stokDurumlari,
        'kritikStoklar': kritikStoklar,
        'toplamUrun': stokDurumlari.length,
        'hamVeri': response,
      };
    } catch (e) {
      return {
        'stokDurumlari': <String, Map<String, dynamic>>{},
        'kritikStoklar': <Map<String, dynamic>>[],
        'toplamUrun': 0,
        'hamVeri': <Map<String, dynamic>>[],
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // MALİ RAPORLAR
  // ==============================================

  /// Gelir-gider analizi
  static Future<Map<String, dynamic>> getMaliAnaliz({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      var query = _supabase.from(DbTables.kasaBankaHareketleri).select('*').eq('firma_id', _firmaId);

      if (baslangicTarihi != null) {
        query = query.gte('tarih', baslangicTarihi.toIso8601String().split('T')[0]);
      }
      if (bitisTarihi != null) {
        query = query.lte('tarih', bitisTarihi.toIso8601String().split('T')[0]);
      }

      final response = await query;
      
      double toplamGelir = 0;
      double toplamGider = 0;
      final Map<String, double> kategoriGelirler = {};
      final Map<String, double> kategoriGiderler = {};
      
      for (final hareket in response) {
        final tutar = (hareket['tutar'] as num?)?.toDouble() ?? 0;
        final tip = hareket['islem_tipi']?.toString() ?? '';
        final kategori = hareket['kategori']?.toString() ?? 'Diğer';
        
        if (tip == 'gelir') {
          toplamGelir += tutar;
          kategoriGelirler[kategori] = (kategoriGelirler[kategori] ?? 0) + tutar;
        } else if (tip == 'gider') {
          toplamGider += tutar;
          kategoriGiderler[kategori] = (kategoriGiderler[kategori] ?? 0) + tutar;
        }
      }

      return {
        'toplamGelir': toplamGelir,
        'toplamGider': toplamGider,
        'netKar': toplamGelir - toplamGider,
        'kategoriGelirler': kategoriGelirler,
        'kategoriGiderler': kategoriGiderler,
        'hamVeri': response,
      };
    } catch (e) {
      return {
        'toplamGelir': 0.0,
        'toplamGider': 0.0,
        'netKar': 0.0,
        'kategoriGelirler': <String, double>{},
        'kategoriGiderler': <String, double>{},
        'hamVeri': <Map<String, dynamic>>[],
        'hata': e.toString(),
      };
    }
  }

  // ==============================================
  // GENEL İSTATİSTİKLER
  // ==============================================

  /// Dashboard için özet istatistikler
  static Future<Map<String, dynamic>> getDashboardIstatistikleri() async {
    try {
      // Paralel olarak tüm verileri çek
      final futures = await Future.wait([
        _supabase.from(DbTables.trikoTakip).select('durum, toplam_adet, adet').eq('firma_id', _firmaId),
        _supabase.from(DbTables.kasaBankaHareketleri).select('islem_tipi, tutar').eq('firma_id', _firmaId).limit(1000),
      ]);

      final siparisler = futures[0];
      final maliHareketler = futures[1];

      // Sipariş istatistikleri
      final int toplamSiparis = siparisler.length;
      final int tamamlananSiparis = siparisler.where((s) => s['durum'] == 'tamamlandi').length;
      final int devamEdenSiparis = siparisler.where((s) => s['durum'] == 'devam_ediyor').length;
      final double toplamSiparisAdedi = siparisler.fold(0.0, (sum, s) => sum + ((s['toplam_adet'] ?? s['adet'] ?? 0) as num).toDouble());

      // Mali istatistikler
      final double aylikGelir = maliHareketler
          .where((h) => h['islem_tipi'] == 'gelir')
          .fold(0.0, (sum, h) => sum + ((h['tutar'] as num?)?.toDouble() ?? 0));

      return {
        'siparisIstatistikleri': {
          'toplamSiparis': toplamSiparis,
          'tamamlananSiparis': tamamlananSiparis,
          'devamEdenSiparis': devamEdenSiparis,
          'toplamSiparisAdedi': toplamSiparisAdedi,
          'tamamlanmaOrani': toplamSiparis == 0 ? 0 : (tamamlananSiparis / toplamSiparis * 100),
        },
        'maliIstatistikler': {
          'aylikGelir': aylikGelir,
        },
      };
    } catch (e) {
      // debugPrint('Dashboard istatistikleri yüklenirken hata: $e');
      return {
        'hata': e.toString(),
        'siparisIstatistikleri': {'toplamSiparis': 0, 'tamamlananSiparis': 0, 'devamEdenSiparis': 0, 'toplamSiparisAdedi': 0, 'tamamlanmaOrani': 0},
        'maliIstatistikler': {'aylikGelir': 0},
      };
    }
  }
}
