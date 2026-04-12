import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';

/// Migrasyon sağlık kontrolü ve doğrulama servisi.
/// Platform admin tarafından kullanılır.
class MigrationService {
  static final _client = Supabase.instance.client;

  /// Genel sağlık raporunu döndürür (SQL fonksiyonundan).
  static Future<Map<String, dynamic>> saglikRaporu() async {
    final response = await _client.rpc('migrasyon_saglik_raporu');
    return Map<String, dynamic>.from(response as Map);
  }

  /// firma_id NULL olan tabloları listeler.
  static Future<List<Map<String, dynamic>>> firmaIdKontrol() async {
    final response = await _client.rpc('migrasyon_firma_id_kontrol');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// RLS durumunu kontrol eder.
  static Future<List<Map<String, dynamic>>> rlsKontrol() async {
    final response = await _client.rpc('migrasyon_rls_kontrol');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Migrasyon adımlarını döndürür.
  static Future<List<Map<String, dynamic>>> migrasyonAdimlari() async {
    final response = await _client
        .from(DbTables.migrasyonDurumu)
        .select()
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Firmaya atanmamış kullanıcıları getirir.
  static Future<List<Map<String, dynamic>>> atanamamisKullanicilar() async {
    final response = await _client
        .from('user_roles')
        .select('user_id, role, email')
        .not('user_id', 'in',
            _client.from(DbTables.firmaKullanicilari).select('user_id'));
    return List<Map<String, dynamic>>.from(response);
  }

  /// Aboneliği olmayan aktif firmaları getirir.
  static Future<List<Map<String, dynamic>>> aboneliksizFirmalar() async {
    final response = await _client.rpc('migrasyon_saglik_raporu');
    final rapor = Map<String, dynamic>.from(response as Map);
    final count = rapor['aboneligi_olmayan_firma'] as int? ?? 0;
    if (count == 0) return [];

    final firmalar = await _client
        .from(DbTables.firmalar)
        .select('id, firma_adi, firma_kodu, aktif')
        .eq('aktif', true);

    final abonelikler = await _client
        .from(DbTables.firmaAbonelikleri)
        .select('firma_id')
        .inFilter('durum', ['aktif', 'deneme']);

    final abonelikFirmaIds = (abonelikler as List)
        .map((a) => a['firma_id'] as String)
        .toSet();

    return (firmalar as List)
        .where((f) => !abonelikFirmaIds.contains(f['id']))
        .map((f) => Map<String, dynamic>.from(f))
        .toList();
  }

  /// Tüm tabloların veri özet istatistiklerini getirir.
  static Future<Map<String, int>> tabloIstatistikleri() async {
    final firmaIdKontrolSonuc = await firmaIdKontrol();
    final result = <String, int>{};
    for (final row in firmaIdKontrolSonuc) {
      result[row['tablo_adi'] as String] = (row['toplam_kayit'] as int?) ?? 0;
    }
    return result;
  }
}
