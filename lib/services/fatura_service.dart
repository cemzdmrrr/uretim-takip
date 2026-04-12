import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class FaturaService {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // Faturaları listele (sayfalama ve filtreleme ile)
  static Future<List<FaturaModel>> faturalariListele({
    String? aramaKelimesi,
    String? faturaTuru,
    String? durum,
    String? odemeDurumu,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from(DbTables.faturalar)
          .select('*')
          .eq('firma_id', _firmaId);

      // Filtreleme
      if (aramaKelimesi != null && aramaKelimesi.isNotEmpty) {
        query = query.or('fatura_no.ilike.%$aramaKelimesi%,aciklama.ilike.%$aramaKelimesi%');
      }

      if (faturaTuru != null && faturaTuru.isNotEmpty) {
        query = query.eq('fatura_turu', faturaTuru);
      }

      if (durum != null && durum.isNotEmpty) {
        query = query.eq('durum', durum);
      }

      if (odemeDurumu != null && odemeDurumu.isNotEmpty) {
        query = query.eq('odeme_durumu', odemeDurumu);
      }

      if (baslangicTarihi != null) {
        query = query.gte('fatura_tarihi', baslangicTarihi.toIso8601String());
      }

      if (bitisTarihi != null) {
        query = query.lte('fatura_tarihi', bitisTarihi.toIso8601String());
      }

      // Sıralama ve sayfalama
      final response = await query
          .order('fatura_tarihi', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => FaturaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Faturalar getirilirken hata oluştu: $e');
    }
  }

  // Fatura sayısını getir
  static Future<int> faturaSayisiGetir({
    String? aramaKelimesi,
    String? faturaTuru,
    String? durum,
    String? odemeDurumu,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
  }) async {
    try {
      var query = _supabase.from(DbTables.faturalar).select('*').eq('firma_id', _firmaId);
      
      if (aramaKelimesi != null && aramaKelimesi.isNotEmpty) {
        query = query.or('fatura_no.ilike.%$aramaKelimesi%,aciklama.ilike.%$aramaKelimesi%');
      }
      if (faturaTuru != null && faturaTuru.isNotEmpty) {
        query = query.eq('fatura_turu', faturaTuru);
      }
      if (durum != null && durum.isNotEmpty) {
        query = query.eq('durum', durum);
      }
      if (odemeDurumu != null && odemeDurumu.isNotEmpty) {
        query = query.eq('odeme_durumu', odemeDurumu);
      }
      if (baslangicTarihi != null) {
        query = query.gte('fatura_tarihi', baslangicTarihi.toIso8601String());
      }
      if (bitisTarihi != null) {
        query = query.lte('fatura_tarihi', bitisTarihi.toIso8601String());
      }
      
      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Yeni fatura oluştur
  static Future<FaturaModel> faturaOlustur(Map<String, dynamic> faturaVerileri) async {
    try {
      // Fatura numarasını her zaman kayıt anında yeniden oluştur (çakışma önleme)
      faturaVerileri['fatura_no'] = await sonrakiFaturaNoOlustur(faturaVerileri['fatura_turu'] ?? 'satis');

      faturaVerileri['olusturma_tarihi'] = DateTime.now().toIso8601String();
      faturaVerileri['firma_id'] = _firmaId;
      
      final response = await _supabase
          .from(DbTables.faturalar)
          .insert(faturaVerileri)
          .select()
          .single();

      return FaturaModel.fromJson(response);
    } catch (e) {
      throw Exception('Fatura oluşturulurken hata oluştu: $e');
    }
  }

  // Fatura güncelle
  static Future<FaturaModel> faturaVerileriniGuncelle(int faturaId, Map<String, dynamic> faturaVerileri) async {
    try {
      faturaVerileri['guncelleme_tarihi'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from(DbTables.faturalar)
          .update(faturaVerileri)
          .eq('fatura_id', faturaId)
          .select()
          .single();

      return FaturaModel.fromJson(response);
    } catch (e) {
      throw Exception('Fatura güncellenirken hata oluştu: $e');
    }
  }

  // Fatura sil
  static Future<void> faturaSil(int faturaId) async {
    try {
      await _supabase
          .from(DbTables.faturalar)
          .delete()
          .eq('fatura_id', faturaId);
    } catch (e) {
      throw Exception('Fatura silinirken hata oluştu: $e');
    }
  }

  // ID ile fatura getir
  static Future<FaturaModel?> faturaGetir(int faturaId) async {
    try {
      final response = await _supabase
          .from(DbTables.faturalar)
          .select()
          .eq('firma_id', _firmaId)
          .eq('fatura_id', faturaId)
          .maybeSingle();

      if (response == null) return null;
      return FaturaModel.fromJson(response);
    } catch (e) {
      throw Exception('Fatura getirilirken hata oluştu: $e');
    }
  }

  // Fatura kalemlerini getir
  static Future<List<FaturaKalemiModel>> faturaKalemleriniGetir(int faturaId) async {
    try {
      final response = await _supabase
          .from(DbTables.faturaKalemleri)
          .select('*')
          .eq('fatura_id', faturaId)
          .order('id', ascending: true);

      return (response as List).map((json) => FaturaKalemiModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Fatura kalemleri getirilirken hata oluştu: $e');
    }
  }

  // Fatura kalemi ekle
  static Future<FaturaKalemiModel> faturaKalemiEkle(Map<String, dynamic> kalemVerileri) async {
    try {
      kalemVerileri['olusturma_tarihi'] = DateTime.now().toIso8601String();
      // firma_id yoksa ekle
      if (kalemVerileri['firma_id'] == null) {
        kalemVerileri['firma_id'] = TenantManager.instance.requireFirmaId;
      }
      kalemVerileri.remove('sira_no');
      kalemVerileri.remove('kalem_id');
      
      final response = await _supabase
          .from(DbTables.faturaKalemleri)
          .insert(kalemVerileri)
          .select()
          .single();

      return FaturaKalemiModel.fromJson(response);
    } catch (e) {
      throw Exception('Fatura kalemi eklenirken hata oluştu: $e');
    }
  }

  // Fatura kalemi güncelle
  static Future<FaturaKalemiModel> faturaKalemiGuncelle(int kalemId, Map<String, dynamic> kalemVerileri) async {
    try {
      final response = await _supabase
          .from(DbTables.faturaKalemleri)
          .update(kalemVerileri)
          .eq('id', kalemId)
          .select()
          .single();

      return FaturaKalemiModel.fromJson(response);
    } catch (e) {
      throw Exception('Fatura kalemi güncellenirken hata oluştu: $e');
    }
  }

  // Fatura kalemi sil
  static Future<void> faturaKalemiSil(int kalemId) async {
    try {
      await _supabase
          .from(DbTables.faturaKalemleri)
          .delete()
          .eq('id', kalemId);
    } catch (e) {
      throw Exception('Fatura kalemi silinirken hata oluştu: $e');
    }
  }

  // Müşteri faturalarını getir
  static Future<List<FaturaModel>> musteriFaturalariniGetir(int musteriId) async {
    try {
      final response = await _supabase
          .from(DbTables.faturalar)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('musteri_id', musteriId)
          .order('fatura_tarihi', ascending: false);

      return (response as List).map((json) => FaturaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Müşteri faturaları getirilirken hata oluştu: $e');
    }
  }

  // Tedarikçi faturalarını getir
  static Future<List<FaturaModel>> tedarikciFaturalariniGetir(int tedarikciId) async {
    try {
      final response = await _supabase
          .from(DbTables.faturalar)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('tedarikci_id', tedarikciId)
          .order('fatura_tarihi', ascending: false);

      return (response as List).map((json) => FaturaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Tedarikçi faturaları getirilirken hata oluştu: $e');
    }
  }

  // Fatura türlerini getir
  static List<String> faturaTurleriniGetir() {
    return [
      'satis',
      'alis',
      'iade',
      'proforma'
    ];
  }

  // Fatura durumlarını getir
  static List<String> faturaDurumlariniGetir() {
    return [
      'taslak',
      'onaylandi',
      'iptal',
      'gonderildi'
    ];
  }

  // Ödeme durumlarını getir
  static List<String> odemeDurumlariniGetir() {
    return [
      'odenmedi',
      'kismi',
      'odendi'
    ];
  }

  // İstatistikleri getir
  static Future<Map<String, dynamic>> istatistikleriGetir() async {
    try {
      final tumFaturalar = await _supabase
          .from(DbTables.faturalar)
          .select('fatura_turu, durum, odeme_durumu, toplam_tutar')
          .eq('firma_id', _firmaId);

      final list = tumFaturalar as List;
      final toplam = list.length;
      final satislar = list.where((item) => item['fatura_turu'] == 'satis').length;
      final alislar = list.where((item) => item['fatura_turu'] == 'alis').length;
      final bekleyenOdemeler = list.where((item) => item['odeme_durumu'] == 'odenmedi').length;

      // Toplam ciro hesaplama (satış faturaları)
      final satisFaturalari = list.where((item) => item['fatura_turu'] == 'satis');
      final toplamCiro = satisFaturalari.fold<double>(0, (sum, item) => sum + (item['toplam_tutar']?.toDouble() ?? 0));

      // Bekleyen ödeme tutarı
      final bekleyenOdemeTutari = list
          .where((item) => item['odeme_durumu'] == 'odenmedi')
          .fold<double>(0, (sum, item) => sum + (item['toplam_tutar']?.toDouble() ?? 0));

      return {
        'toplam': toplam,
        'satislar': satislar,
        'alislar': alislar,
        'bekleyen_odemeler': bekleyenOdemeler,
        'toplam_ciro': toplamCiro,
        'bekleyen_odeme_tutari': bekleyenOdemeTutari,
      };
    } catch (e) {
      return {
        'toplam': 0,
        'satislar': 0,
        'alislar': 0,
        'bekleyen_odemeler': 0,
        'toplam_ciro': 0.0,
        'bekleyen_odeme_tutari': 0.0,
      };
    }
  }

  // Özel fatura numarası oluştur
  static Future<String> _yeniFaturaNoOlustur(String faturaTuru) async {
    try {
      final now = DateTime.now();
      final yil = now.year.toString();
      final ay = now.month.toString().padLeft(2, '0');
      
      String prefix;
      switch (faturaTuru) {
        case 'satis':
          prefix = 'SF';
          break;
        case 'alis':
          prefix = 'AF';
          break;
        case 'iade':
          prefix = 'IF';
          break;
        case 'proforma':
          prefix = 'PF';
          break;
        default:
          prefix = 'F';
      }

      // Bu ay bu tür için kaç fatura var?
      final response = await _supabase
          .from(DbTables.faturalar)
          .select('fatura_no')
          .eq('firma_id', _firmaId)
          .eq('fatura_turu', faturaTuru)
          .gte('fatura_tarihi', DateTime(now.year, now.month, 1).toIso8601String())
          .lt('fatura_tarihi', DateTime(now.year, now.month + 1, 1).toIso8601String());

      final mevcutSayisi = (response as List).length + 1;
      final siraNo = mevcutSayisi.toString().padLeft(4, '0');

      return '$prefix$yil$ay$siraNo';
    } catch (e) {
      // Hata durumunda basit numara üret
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      return 'F$timestamp';
    }
  }

  // Tamamlanan siparişten fatura oluştur
  static Future<FaturaModel> siparistenFaturaOlustur(int modelId) async {
    try {
      // Model bilgilerini getir
      final modelResponse = await _supabase
          .from(DbTables.trikoTakip)
          .select('''
            *, 
            musteri:musteri_id(ad, sirket, adres, vergi_no, vergi_dairesi)
          ''')
          .eq('firma_id', _firmaId)
          .eq('id', modelId)
          .single();


      // Müşteri bilgileri
      final musteri = modelResponse['musteri'];
      final faturaAdres = musteri?['adres'] ?? '';
      
      // Fatura oluştur
      final faturaVerileri = {
        'fatura_turu': 'satis',
        'fatura_tarihi': DateTime.now().toIso8601String(),
        'musteri_id': modelResponse['musteri_id'],
        'fatura_adres': faturaAdres,
        'vergi_dairesi': musteri?['vergi_dairesi'],
        'vergi_no': musteri?['vergi_no'],
        'ara_toplam_tutar': 0.0, // Kalkulasyondan sonra güncellenecek
        'kdv_tutari': 0.0,
        'toplam_tutar': 0.0,
        'durum': 'taslak',
        'aciklama': 'Sipariş No: ${modelResponse['marka']} - ${modelResponse['item_no']} otomatik faturası',
        'kur': 'TRY',
        'kur_orani': 1.0,
        'olusturan_kullanici': 'sistem',
      };

      final fatura = await faturaOlustur(faturaVerileri);

      // Fatura kalemi oluştur
      final kalemVerileri = {
        'fatura_id': fatura.faturaId,
        'firma_id': TenantManager.instance.requireFirmaId,
        'urun_adi': '${modelResponse['marka']} - ${modelResponse['item_no']}',
        'aciklama': 'Renk: ${modelResponse['renk']}, Ürün Cinsi: ${modelResponse['urun_cinsi']}',
        'miktar': modelResponse['adet']?.toDouble() ?? 1.0,
        'birim': 'adet',
        'birim_fiyat': 0.0,
        'kdv_orani': 20.0,
        'iskonto_orani': 0.0,
        'iskonto_tutari': 0.0,
        'kdv_tutari': 0.0,
        'toplam_tutar': 0.0,
        'model_id': modelId,
      };

      await faturaKalemiEkle(kalemVerileri);

      return fatura;
    } catch (e) {
      throw Exception('Siparişten fatura oluşturulurken hata: $e');
    }
  }

  // Fatura durumu güncelle
  static Future<void> faturaDurumGuncelle(int faturaId, String yeniDurum) async {
    try {
      await _supabase
          .from(DbTables.faturalar)
          .update({
            'durum': yeniDurum,
            'guncelleme_tarihi': DateTime.now().toIso8601String(),
          })
          .eq('fatura_id', faturaId);
    } catch (e) {
      throw Exception('Fatura durumu güncellenirken hata: $e');
    }
  }

  // Ödeme ekle (Kasa/Banka Hareket entegrasyonu ile)
  static Future<void> odemeEkle(
    int faturaId, 
    double odemeTutari, 
    String? aciklama, {
    String? kasaBankaId,
    String? paraBirimi = 'TRY',
    String? referansNo,
    DateTime? islemTarihi,
  }) async {
    try {
      // Mevcut faturayı getir
      final faturaResponse = await _supabase
          .from(DbTables.faturalar)
          .select('odenen_tutar, toplam_tutar, fatura_no')
          .eq('fatura_id', faturaId)
          .single();

      final mevcutOdenenTutar = (faturaResponse['odenen_tutar'] as num?)?.toDouble() ?? 0.0;
      final toplamTutar = (faturaResponse['toplam_tutar'] as num?)?.toDouble() ?? 0.0;
      final faturaNo = faturaResponse['fatura_no'] ?? '';
      final yeniOdenenTutar = mevcutOdenenTutar + odemeTutari;

      // Ödeme durumunu belirle
      String yeniOdemeDurumu;
      if (yeniOdenenTutar >= toplamTutar) {
        yeniOdemeDurumu = 'odendi';
      } else if (yeniOdenenTutar > 0) {
        yeniOdemeDurumu = 'kismi';
      } else {
        yeniOdemeDurumu = 'odenmedi';
      }

      // Faturayı güncelle
      await _supabase
          .from(DbTables.faturalar)
          .update({
            'odenen_tutar': yeniOdenenTutar,
            'odeme_durumu': yeniOdemeDurumu,
            'guncelleme_tarihi': DateTime.now().toIso8601String(),
          })
          .eq('fatura_id', faturaId);

      // Kasa/Banka hareket kaydı ekle (eğer kasa/banka hesabı belirtilmişse)
      if (kasaBankaId != null) {
        // Kasa/Banka Hareket Service'ini import etmemiz gerekiyor
        // Bu entegrasyonu başka bir metodla yapacağız
        final hareketData = {
          'kasa_banka_id': kasaBankaId,
          'hareket_tipi': 'cikis',
          'tutar': odemeTutari,
          'para_birimi': paraBirimi ?? 'TRY',
          'aciklama': aciklama ?? 'Fatura ödemesi - $faturaNo',
          'kategori': 'fatura_odeme',
          'fatura_id': faturaId.toString(),
          'referans_no': referansNo,
          'islem_tarihi': (islemTarihi ?? DateTime.now()).toIso8601String(),
          'olusturma_tarihi': DateTime.now().toIso8601String(),
          'olusturan_kullanici': _supabase.auth.currentUser?.email ?? 'sistem',
          'onaylanmis_mi': true, // Fatura ödemeleri otomatik onaylı
        };

        hareketData['firma_id'] = _firmaId;

        await _supabase
            .from(DbTables.kasaBankaHareketleri)
            .insert(hareketData);
      }

      // Ödeme geçmişi tablosuna kayıt ekle (gelecekte)
      // await _supabase.from(DbTables.odemeGecmisi).insert({...});

    } catch (e) {
      throw Exception('Ödeme eklenirken hata: $e');
    }
  }

  // Sonraki fatura no oluştur
  static Future<String> sonrakiFaturaNoOlustur(String faturaTuru) async {
    try {
      final yil = DateTime.now().year;
      final prefix = _getFaturaPrefix(faturaTuru);
      
      // Son fatura nosunu bul - firma bazlı
      final response = await _supabase
          .from(DbTables.faturalar)
          .select('fatura_no')
          .eq('firma_id', _firmaId)
          .like('fatura_no', '$prefix-$yil-%')
          .order('fatura_no', ascending: false)
          .limit(1);

      int sonrakiNo = 1;
      if (response.isNotEmpty) {
        final sonFaturaNo = response.first['fatura_no'] as String;
        final parts = sonFaturaNo.split('-');
        if (parts.length >= 3) {
          sonrakiNo = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      return '$prefix-$yil-${sonrakiNo.toString().padLeft(3, '0')}';
    } catch (e) {
      // Hata durumunda basit bir format döndür
      final yil = DateTime.now().year;
      final prefix = _getFaturaPrefix(faturaTuru);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      return '$prefix-$yil-$timestamp';
    }
  }

  static String _getFaturaPrefix(String faturaTuru) {
    switch (faturaTuru) {
      case 'satis':
        return 'SF';
      case 'alis':
        return 'AF';
      case 'iade':
        return 'IF';
      case 'proforma':
        return 'PF';
      default:
        return 'FT';
    }
  }

  // Fatura ekle (fatura + kalemleri)
  static Future<int> faturaEkle(FaturaModel fatura, List<FaturaKalemiModel> kalemler) async {
    try {
      // Önce faturayı ekle
      final faturaData = fatura.toMap();
      faturaData['firma_id'] = _firmaId;
      final faturaResponse = await _supabase
          .from(DbTables.faturalar)
          .insert(faturaData)
          .select('fatura_id')
          .single();

      final faturaId = faturaResponse['fatura_id'] as int;

      // Sonra kalemleri ekle
      if (kalemler.isNotEmpty) {
        final kalemData = kalemler.map((kalem) {
          return {
            'fatura_id': faturaId,
            'firma_id': _firmaId,
            'urun_kodu': kalem.urunKodu,
            'urun_adi': kalem.urunAdi,
            'aciklama': kalem.aciklama,
            'miktar': kalem.miktar,
            'birim': kalem.birim,
            'birim_fiyat': kalem.birimFiyat,
            'iskonto_orani': kalem.iskonto,
            'iskonto_tutari': kalem.iskontoTutar,
            'kdv_orani': kalem.kdvOrani,
            'kdv_tutari': kalem.kdvTutar,
            'toplam_tutar': kalem.satirTutar,
            'model_id': kalem.modelId,
            'olusturma_tarihi': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase
            .from(DbTables.faturaKalemleri)
            .insert(kalemData);
      }

      return faturaId;
    } catch (e) {
      throw Exception('Fatura eklenirken hata: $e');
    }
  }

  // Fatura güncelle
  static Future<void> faturaGuncelle(FaturaModel fatura, List<FaturaKalemiModel> kalemler) async {
    try {
      // Önce faturayı güncelle
      await _supabase
          .from(DbTables.faturalar)
          .update(fatura.toMap())
          .eq('fatura_id', fatura.faturaId!);

      // Mevcut kalemleri sil
      await _supabase
          .from(DbTables.faturaKalemleri)
          .delete()
          .eq('fatura_id', fatura.faturaId!);

      // Yeni kalemleri ekle
      if (kalemler.isNotEmpty) {
        final kalemData = kalemler.map((kalem) {
          return {
            'fatura_id': fatura.faturaId!,
            'firma_id': _firmaId,
            'urun_kodu': kalem.urunKodu,
            'urun_adi': kalem.urunAdi,
            'aciklama': kalem.aciklama,
            'miktar': kalem.miktar,
            'birim': kalem.birim,
            'birim_fiyat': kalem.birimFiyat,
            'iskonto_orani': kalem.iskonto,
            'iskonto_tutari': kalem.iskontoTutar,
            'kdv_orani': kalem.kdvOrani,
            'kdv_tutari': kalem.kdvTutar,
            'toplam_tutar': kalem.satirTutar,
            'model_id': kalem.modelId,
            'olusturma_tarihi': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase
            .from(DbTables.faturaKalemleri)
            .insert(kalemData);
      }
    } catch (e) {
      throw Exception('Fatura güncellenirken hata: $e');
    }
  }
}
