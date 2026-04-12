import 'package:flutter/foundation.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SistemAyarlariService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Ayar değeri getir
  static Future<double> getAyarDegeri(String ayarKodu, {double varsayilan = 0}) async {
    try {
      final response = await _client
          .from(DbTables.sistemAyarlari)
          .select('ayar_degeri')
          .eq('ayar_kodu', ayarKodu)
          .maybeSingle();
      
      if (response != null) {
        return (response['ayar_degeri'] as num?)?.toDouble() ?? varsayilan;
      }
      return varsayilan;
    } catch (e) {
      debugPrint('Ayar değeri getirme hatası: $e');
      return varsayilan;
    }
  }

  // Ayar değeri güncelle (sadece admin)
  static Future<bool> updateAyarDegeri(String ayarKodu, double yeniDeger) async {
    try {
      await _client
          .from(DbTables.sistemAyarlari)
          .update({'ayar_degeri': yeniDeger, 'updated_at': DateTime.now().toIso8601String()})
          .eq('ayar_kodu', ayarKodu);
      return true;
    } catch (e) {
      debugPrint('Ayar değeri güncelleme hatası: $e');
      return false;
    }
  }

  // Tüm ayarları getir
  static Future<List<Map<String, dynamic>>> getTumAyarlar() async {
    try {
      final response = await _client
          .from(DbTables.sistemAyarlari)
          .select('*')
          .order('ayar_adi');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Tüm ayarları getirme hatası: $e');
      return [];
    }
  }

  // Yemek ücretleri için özel metodlar
  static Future<double> getPazarYemekUcreti() async {
    return await getAyarDegeri('PAZAR_YEMEK_UCRETI', varsayilan: 50.0);
  }

  static Future<double> getBayramYemekUcreti() async {
    return await getAyarDegeri('BAYRAM_YEMEK_UCRETI', varsayilan: 75.0);
  }

  static Future<bool> setPazarYemekUcreti(double ucret) async {
    return await updateAyarDegeri('PAZAR_YEMEK_UCRETI', ucret);
  }

  static Future<bool> setBayramYemekUcreti(double ucret) async {
    return await updateAyarDegeri('BAYRAM_YEMEK_UCRETI', ucret);
  }
}
