import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_logger.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;
  
  // Şirket bilgilerini getir
  static Future<Map<String, dynamic>?> getCompanySettings() async {
    try {
      final response = await _client
          .from(DbTables.sirketBilgileri)
          .select()
          .eq('firma_id', _firmaId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      AppLogger.error('SupabaseService', 'Şirket bilgileri getirme hatası', e);
      return null;
    }
  }
  
  // Şirket bilgilerini kaydet/güncelle
  static Future<bool> saveCompanySettings(Map<String, dynamic> data) async {
    try {
      // Mevcut sütun isimlerine göre düzenle
      final mappedData = {
        'unvan': data['sirket_adi'] ?? '',
        'vergi_no': data['vergi_numarasi'] ?? '',
        'vergi_dairesi': data['vergi_dairesi'] ?? 'Belirtilmemiş',
        'sicil_no': data['ticaret_sicil_no'] ?? '',
        'sgk_sicil_no': data['sgk_sicil_no'] ?? '',
        'adres': data['adres'] ?? '',
        'telefon': data['telefon'] ?? '',
        'email': data['email'] ?? '',
        'yetkili': data['yetkili_bilgi'] ?? '',
        'iban': data['iban'] ?? '',
        'banka': data['banka_adi'] ?? '',
        'faaliyet': data['faaliyet'] ?? 'Genel',
        'kurulus_yili': data['kurulus_yili'] ?? '2024',
        'web': data['web'] ?? '',
        'guncelleme_tarihi': 'now()'
      };
      
      final existing = await getCompanySettings();
      
      if (existing != null) {
        // Güncelle
        await _client
            .from(DbTables.sirketBilgileri)
            .update(mappedData)
            .eq('id', existing['id']);
      } else {
        // Yeni kayıt
        await _client
            .from(DbTables.sirketBilgileri)
            .insert({...mappedData, 'firma_id': _firmaId});
      }
      
      return true;
    } catch (e) {
      AppLogger.error('SupabaseService', 'Şirket bilgileri kaydetme hatası', e);
      return false;
    }
  }
  
  // Sistem ayarlarını key-value olarak getir
  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await _client
          .from(DbTables.sistemAyarlari)
          .select('anahtar, deger')
          .eq('firma_id', _firmaId);
      
      final Map<String, dynamic> settings = {};
      for (var item in response) {
        settings[item['anahtar']] = item['deger'];
      }
      
      return settings;
    } catch (e) {
      AppLogger.error('SupabaseService', 'Sistem ayarları getirme hatası', e);
      return {};
    }
  }
  
  // Sistem ayarlarını kaydet/güncelle
  static Future<bool> saveSystemSettings(Map<String, dynamic> data) async {
    try {
      // Her ayarı ayrı ayrı kaydet/güncelle
      for (var entry in data.entries) {
        // Önce mevcut kaydı kontrol et
        final existing = await _client
            .from(DbTables.sistemAyarlari)
            .select('id')
            .eq('firma_id', _firmaId)
            .eq('anahtar', entry.key)
            .maybeSingle();
        
        if (existing != null) {
          // Güncelle
          await _client
              .from(DbTables.sistemAyarlari)
              .update({
                'deger': entry.value.toString(),
                'guncelleme_tarihi': 'now()'
              })
              .eq('anahtar', entry.key);
        } else {
          // Yeni kayıt ekle
          await _client
              .from(DbTables.sistemAyarlari)
              .insert({
                'firma_id': _firmaId,
                'anahtar': entry.key,
                'deger': entry.value.toString(),
                'aciklama': entry.key,
                'tip': 'sirket',
                'guncelleme_tarihi': 'now()'
              });
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.error('SupabaseService', 'Sistem ayarları kaydetme hatası', e);
      return false;
    }
  }
  
  // Gelir vergisi dilimlerini getir
  static Future<List<Map<String, dynamic>>> getTaxBrackets() async {
    try {
      final response = await _client
          .from(DbTables.gelirVergisiDilimleri)
          .select()
          .eq('firma_id', _firmaId)
          .order('min_gelir');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('SupabaseService', 'Vergi dilimleri getirme hatası', e);
      return [];
    }
  }
  
  // Gelir vergisi dilimlerini güncelle
  static Future<bool> updateTaxBrackets(List<Map<String, dynamic>> brackets) async {
    try {
      // Mevcut dilimleri sil
      await _client.from(DbTables.gelirVergisiDilimleri).delete().neq('id', 0);
      
      // Yeni dilimleri ekle
      final bracketsWithFirma = brackets.map((b) => {...b, 'firma_id': _firmaId}).toList();
      await _client.from(DbTables.gelirVergisiDilimleri).insert(bracketsWithFirma);
      
      return true;
    } catch (e) {
      AppLogger.error('SupabaseService', 'Vergi dilimleri güncelleme hatası', e);
      return false;
    }
  }
}
