import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class SistemAyarlariService {
  static final SupabaseClient _client = Supabase.instance.client;
  static String get _firmaId => TenantManager.instance.requireFirmaId;

  static Future<double> getAyarDegeri(
    String ayarKodu, {
    double varsayilan = 0,
  }) async {
    try {
      final response = await _client
          .from(DbTables.sistemAyarlari)
          .select('deger')
          .eq('firma_id', _firmaId)
          .eq('anahtar', ayarKodu)
          .maybeSingle();

      if (response == null) return varsayilan;

      final raw = response['deger'];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString().replaceAll(',', '.') ?? '') ??
          varsayilan;
    } catch (e) {
      debugPrint('Ayar değeri getirme hatası: $e');
      return varsayilan;
    }
  }

  static Future<bool> updateAyarDegeri(
    String ayarKodu,
    double yeniDeger,
  ) async {
    try {
      final mevcut = await _client
          .from(DbTables.sistemAyarlari)
          .select('id')
          .eq('firma_id', _firmaId)
          .eq('anahtar', ayarKodu)
          .maybeSingle();

      final data = {
        'firma_id': _firmaId,
        'anahtar': ayarKodu,
        'deger': yeniDeger.toString(),
        'aciklama': ayarKodu,
        'tip': 'personel',
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
      };

      if (mevcut == null) {
        await _client.from(DbTables.sistemAyarlari).insert(data);
      } else {
        await _client
            .from(DbTables.sistemAyarlari)
            .update(data)
            .eq('firma_id', _firmaId)
            .eq('anahtar', ayarKodu);
      }

      return true;
    } catch (e) {
      debugPrint('Ayar değeri güncelleme hatası: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTumAyarlar() async {
    try {
      final response = await _client
          .from(DbTables.sistemAyarlari)
          .select('*')
          .eq('firma_id', _firmaId)
          .order('anahtar');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Tüm ayarları getirme hatası: $e');
      return [];
    }
  }

  static Future<double> getPazarYemekUcreti() async {
    return getAyarDegeri('PAZAR_YEMEK_UCRETI', varsayilan: 50.0);
  }

  static Future<double> getBayramYemekUcreti() async {
    return getAyarDegeri('BAYRAM_YEMEK_UCRETI', varsayilan: 75.0);
  }

  static Future<bool> setPazarYemekUcreti(double ucret) async {
    return updateAyarDegeri('PAZAR_YEMEK_UCRETI', ucret);
  }

  static Future<bool> setBayramYemekUcreti(double ucret) async {
    return updateAyarDegeri('BAYRAM_YEMEK_UCRETI', ucret);
  }
}
