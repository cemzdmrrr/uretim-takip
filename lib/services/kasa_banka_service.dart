import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class KasaBankaService {
  static final _supabase = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // Tüm kasa/banka hesaplarını getir
  static Future<List<KasaBankaModel>> hesaplariListele({
    String? aramaKelimesi,
    String? hesapTuru,
    bool? aktif,
    String? kur,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from(DbTables.kasaBankaHesaplari)
          .select('*')
          .eq('firma_id', _firmaId);

      // Filtreleme
      if (aramaKelimesi != null && aramaKelimesi.isNotEmpty) {
        query = query.or('hesap_adi.ilike.%$aramaKelimesi%,hesap_no.ilike.%$aramaKelimesi%');
      }

      if (hesapTuru != null && hesapTuru.isNotEmpty) {
        query = query.eq('tip', hesapTuru.toLowerCase());
      }

      if (aktif != null) {
        final String durumu = aktif ? 'aktif' : 'pasif';
        query = query.eq('durumu', durumu);
      }

      if (kur != null && kur.isNotEmpty) {
        query = query.eq('doviz_kodu', kur);
      }

      // Sıralama ve sayfalama
      final response = await query
          .order('olusturma_tarihi', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => KasaBankaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Kasa/Banka hesapları getirilirken hata oluştu: $e');
    }
  }

  // Hesap sayısını getir
  static Future<int> hesapSayisiGetir({
    String? aramaKelimesi,
    String? hesapTuru,
    bool? aktif,
    String? kur,
  }) async {
    try {
      var query = _supabase.from(DbTables.kasaBankaHesaplari).select('*').eq('firma_id', _firmaId);
      
      if (aramaKelimesi != null && aramaKelimesi.isNotEmpty) {
        query = query.or('hesap_adi.ilike.%$aramaKelimesi%,hesap_no.ilike.%$aramaKelimesi%');
      }
      if (hesapTuru != null && hesapTuru.isNotEmpty) {
        query = query.eq('tip', hesapTuru.toLowerCase());
      }
      if (aktif != null) {
        final String durumu = aktif ? 'aktif' : 'pasif';
        query = query.eq('durumu', durumu);
      }
      if (kur != null && kur.isNotEmpty) {
        query = query.eq('doviz_kodu', kur);
      }
      
      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Yeni hesap ekle
  static Future<int> hesapEkle(KasaBankaModel hesap) async {
    try {
      final hesapData = hesap.toJson();
      hesapData['firma_id'] = _firmaId;
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .insert(hesapData)
          .select('id')
          .single();

      return response['id'] as int;
    } catch (e) {
      throw Exception('Kasa/Banka hesabı eklenirken hata oluştu: $e');
    }
  }

  // Hesap güncelle
  static Future<void> hesapGuncelle(KasaBankaModel hesap) async {
    try {
      await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .update(hesap.toJson())
          .eq('id', hesap.id!);
    } catch (e) {
      throw Exception('Kasa/Banka hesabı güncellenirken hata oluştu: $e');
    }
  }

  // Hesap sil
  static Future<void> hesapSil(int hesapId) async {
    try {
      await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .delete()
          .eq('id', hesapId);
    } catch (e) {
      throw Exception('Kasa/Banka hesabı silinirken hata oluştu: $e');
    }
  }

  // ID'ye göre hesap getir
  static Future<KasaBankaModel?> hesapGetir(int hesapId) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('id', hesapId)
          .single();

      return KasaBankaModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Aktif hesapları getir (dropdown'lar için)
  static Future<List<KasaBankaModel>> aktifHesaplariGetir() async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('durumu', 'AKTIF')
          .order('ad');

      return (response as List).map((json) => KasaBankaModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Toplam bakiye hesapla (kura göre)
  static Future<Map<String, double>> toplamBakiyeHesapla() async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .select('doviz_kodu, bakiye')
          .eq('firma_id', _firmaId)
          .eq('durumu', 'aktif');

      final Map<String, double> toplamlar = {};
      
      for (final hesap in response) {
        final kur = (hesap['doviz_kodu'] ?? 'TRY') as String;
        final bakiye = (hesap['bakiye'] ?? 0.0).toDouble();
        
        toplamlar[kur] = (toplamlar[kur] ?? 0.0) + bakiye;
      }

      return toplamlar;
    } catch (e) {
      return {};
    }
  }

  // Hesap türlerine göre dağılım
  static Future<Map<String, int>> hesapTuruDagilimi() async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .select('tip')
          .eq('firma_id', _firmaId)
          .eq('durumu', 'AKTIF');

      final Map<String, int> dagilim = {};
      
      for (final hesap in response) {
        final tur = hesap['tip'] as String;
        dagilim[tur] = (dagilim[tur] ?? 0) + 1;
      }

      return dagilim;
    } catch (e) {
      return {};
    }
  }

  // Bakiye güncelle (hareket sonrası)
  static Future<void> bakiyeGuncelle(int hesapId, double yeniBakiye) async {
    try {
      await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .update({
            'bakiye': yeniBakiye,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', hesapId);
    } catch (e) {
      throw Exception('Bakiye güncellenirken hata oluştu: $e');
    }
  }

  // Hesap durumunu değiştir (aktif/pasif)
  static Future<void> hesapDurumDegistir(int hesapId, bool aktif) async {
    try {
      await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .update({
            'durumu': aktif ? 'AKTIF' : 'PASIF',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', hesapId);
    } catch (e) {
      throw Exception('Hesap durumu değiştirilirken hata oluştu: $e');
    }
  }

  // Instance metodları (UI'dan kullanım için)
  Future<KasaBankaModel> kasaBankaEkle(KasaBankaModel kasaBanka) async {
    try {
      final data = kasaBanka.toJson();
      data.remove('id'); // ID'yi otomatik oluşturacak
      data['firma_id'] = _firmaId;
      
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .insert(data)
          .select()
          .single();

      return KasaBankaModel.fromJson(response);
    } catch (e) {
      throw Exception('Kasa/Banka hesabı eklenirken hata oluştu: $e');
    }
  }

  Future<KasaBankaModel> kasaBankaGuncelle(KasaBankaModel kasaBanka) async {
    try {
      final data = kasaBanka.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .update(data)
          .eq('id', kasaBanka.id!)
          .select()
          .single();

      return KasaBankaModel.fromJson(response);
    } catch (e) {
      throw Exception('Kasa/Banka hesabı güncellenirken hata oluştu: $e');
    }
  }

  Future<KasaBankaModel?> kasaBankaGetir(int id) async {
    try {
      final response = await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return KasaBankaModel.fromJson(response);
    } catch (e) {
      throw Exception('Kasa/Banka hesabı getirilirken hata oluştu: $e');
    }
  }

  Future<void> kasaBankaSil(int id) async {
    try {
      await _supabase
          .from(DbTables.kasaBankaHesaplari)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Kasa/Banka hesabı silinirken hata oluştu: $e');
    }
  }
}
