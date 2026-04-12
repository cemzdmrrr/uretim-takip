import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class TedarikciService {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // Tedarikçileri listele (sayfalama ve filtreleme ile)
  static Future<List<TedarikciModel>> tedarikcileriListele({
    String? aramaKelimesi,
    String? tedarikciTipi,
    String? durum,
    String? faaliyet,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from(DbTables.tedarikciler)
          .select('*')
          .eq('firma_id', _firmaId);

      // Filtreleme
      if (aramaKelimesi != null && aramaKelimesi.isNotEmpty) {
        query = query.or('ad.ilike.%$aramaKelimesi%,sirket.ilike.%$aramaKelimesi%,telefon.ilike.%$aramaKelimesi%');
      }

      if (tedarikciTipi != null && tedarikciTipi.isNotEmpty) {
        query = query.eq('tedarikci_tipi', tedarikciTipi);
      }

      if (durum != null && durum.isNotEmpty) {
        query = query.eq('durum', durum);
      }

      if (faaliyet != null && faaliyet.isNotEmpty) {
        query = query.eq('faaliyet', faaliyet);
      }

      // Sıralama ve sayfalama
      final response = await query
          .order('kayit_tarihi', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => TedarikciModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Tedarikçiler getirilirken hata oluştu: $e');
    }
  }

  // Tedarikçi sayısını getir (basit yöntem)
  static Future<int> tedarikciSayisiGetir({
    String? aramaKelimesi,
    String? tedarikciTipi,
    String? durum,
    String? faaliyet,
  }) async {
    try {
      var query = _supabase.from(DbTables.tedarikciler).select('*').eq('firma_id', _firmaId);
      
      if (aramaKelimesi != null && aramaKelimesi.isNotEmpty) {
        query = query.or('ad.ilike.%$aramaKelimesi%,sirket.ilike.%$aramaKelimesi%,telefon.ilike.%$aramaKelimesi%');
      }
      if (tedarikciTipi != null && tedarikciTipi.isNotEmpty) {
        query = query.eq('tedarikci_tipi', tedarikciTipi);
      }
      if (durum != null && durum.isNotEmpty) {
        query = query.eq('durum', durum);
      }
      if (faaliyet != null && faaliyet.isNotEmpty) {
        query = query.eq('faaliyet', faaliyet);
      }
      
      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Tedarikçi ekle
  static Future<TedarikciModel> tedarikciEkle(Map<String, dynamic> tedarikciVerileri) async {
    try {
      tedarikciVerileri['kayit_tarihi'] = DateTime.now().toIso8601String();
      tedarikciVerileri['firma_id'] = _firmaId;
      
      final response = await _supabase
          .from(DbTables.tedarikciler)
          .insert(tedarikciVerileri)
          .select()
          .single();

      return TedarikciModel.fromJson(response);
    } catch (e) {
      throw Exception('Tedarikçi eklenirken hata oluştu: $e');
    }
  }

  // Tedarikçi güncelle
  static Future<TedarikciModel> tedarikciGuncelle(int tedarikciId, Map<String, dynamic> tedarikciVerileri) async {
    try {
      tedarikciVerileri['guncelleme_tarihi'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from(DbTables.tedarikciler)
          .update(tedarikciVerileri)
          .eq('id', tedarikciId)
          .select()
          .single();

      return TedarikciModel.fromJson(response);
    } catch (e) {
      throw Exception('Tedarikçi güncellenirken hata oluştu: $e');
    }
  }

  // Tedarikçi sil
  static Future<void> tedarikciSil(int tedarikciId) async {
    try {
      // Önce ilişkili atamaları temizle (foreign key constraint önlemek için)
      final atamaTablolari = [
        DbTables.dokumaAtamalari,
        DbTables.konfeksiyonAtamalari,
        DbTables.nakisAtamalari,
        DbTables.yikamaAtamalari,
        DbTables.ilikDugmeAtamalari,
        DbTables.utuAtamalari,
      ];
      
      for (final tablo in atamaTablolari) {
        try {
          // tedarikci_id referanslarını null yap
          await _supabase
              .from(tablo)
              .update({'tedarikci_id': null})
              .eq('tedarikci_id', tedarikciId);
        } catch (e) {
          // Tablo veya sütun yoksa devam et
        }
      }
      
      // İplik stokları referanslarını null yap
      try {
        await _supabase
            .from(DbTables.iplikStoklari)
            .update({'tedarikci_id': null})
            .eq('tedarikci_id', tedarikciId);
      } catch (e) {
        // Tablo veya sütun yoksa devam et
      }
      
      // Aksesuar stokları referanslarını null yap
      try {
        await _supabase
            .from(DbTables.aksesuarStok)
            .update({'tedarikci_id': null})
            .eq('tedarikci_id', tedarikciId);
      } catch (e) {
        // Tablo veya sütun yoksa devam et
      }
      
      // İplik siparişleri referanslarını null yap
      try {
        await _supabase
            .from(DbTables.iplikSiparisleri)
            .update({'tedarikci_id': null})
            .eq('tedarikci_id', tedarikciId);
      } catch (e) {
        // Tablo veya sütun yoksa devam et
      }
      
      // Faturalar referanslarını null yap
      try {
        await _supabase
            .from(DbTables.faturalar)
            .update({'tedarikci_id': null})
            .eq('tedarikci_id', tedarikciId);
      } catch (e) {
        // Tablo veya sütun yoksa devam et
      }
      
      // Tedarikçiyi sil
      await _supabase
          .from(DbTables.tedarikciler)
          .delete()
          .eq('id', tedarikciId);
    } catch (e) {
      throw Exception('Tedarikçi silinirken hata oluştu: $e');
    }
  }

  // ID ile tedarikçi getir
  static Future<TedarikciModel?> tedarikciGetir(int tedarikciId) async {
    try {
      final response = await _supabase
          .from(DbTables.tedarikciler)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('id', tedarikciId)
          .maybeSingle();

      if (response == null) return null;
      return TedarikciModel.fromJson(response);
    } catch (e) {
      throw Exception('Tedarikçi getirilirken hata oluştu: $e');
    }
  }

  // Aktif tedarikçileri getir (dropdown için)
  static Future<List<TedarikciModel>> aktifTedarikcileriGetir() async {
    try {
      final response = await _supabase
          .from(DbTables.tedarikciler)
          .select('*')
          .eq('durum', 'aktif')
          .order('ad', ascending: true);

      return (response as List).map((json) => TedarikciModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Aktif tedarikçiler getirilirken hata oluştu: $e');
    }
  }

  // Tedarikçi tiplerini getir
  static List<String> tedarikciTipleriniGetir() {
    return [
      'Üretici',
      'İthalatçı',
      'Distribütör',
      'Bayi',
      'Hizmet Sağlayıcı',
      'Diğer'
    ];
  }

  // Faaliyet alanlarını getir
  static List<String> faaliyetAlanlariniGetir() {
    return [
      'Tekstil',
      'İplik',
      'Aksesuar',
      'Makine',
      'Kimyasal',
      'Ambalaj',
      'Lojistik',
      'Diğer'
    ];
  }

  // Durumları getir
  static List<String> durumlariGetir() {
    return [
      'aktif',
      'pasif',
      'beklemede'
    ];
  }

  // Tedarikçiye ait siparişleri getir
  static Future<List<Map<String, dynamic>>> tedarikciSiparisleriniGetir(int tedarikciId) async {
    try {
      final response = await _supabase
          .from(DbTables.tedarikciSiparisleri)
          .select('*')
          .eq('tedarikci_id', tedarikciId)
          .order('siparis_tarihi', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return []; // Boş liste döndür
    }
  }

  // Tedarikçiye ait ödemeleri getir
  static Future<List<Map<String, dynamic>>> tedarikciOdemeleriniGetir(int tedarikciId) async {
    try {
      final response = await _supabase
          .from(DbTables.tedarikciOdemeleri)
          .select('*')
          .eq('tedarikci_id', tedarikciId)
          .order('odeme_tarihi', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return []; // Boş liste döndür
    }
  }

  // İstatistikleri getir
  static Future<Map<String, dynamic>> istatistikleriGetir() async {
    try {
      final tumTedarikciler = await _supabase
          .from(DbTables.tedarikciler)
          .select('durum');

      final list = tumTedarikciler as List;
      final toplam = list.length;
      final aktif = list.where((item) => item['durum'] == 'aktif').length;
      final pasif = list.where((item) => item['durum'] == 'pasif').length;
      final beklemede = list.where((item) => item['durum'] == 'beklemede').length;

      return {
        'toplam': toplam,
        'aktif': aktif,
        'pasif': pasif,
        'beklemede': beklemede,
      };
    } catch (e) {
      return {
        'toplam': 0,
        'aktif': 0,
        'pasif': 0,
        'beklemede': 0,
      };
    }
  }
}
