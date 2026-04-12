import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Firma (tenant) CRUD, modül yönetimi ve davet işlemleri servisi.
class FirmaService {
  static final _client = Supabase.instance.client;

  /// Yeni firma oluşturur ve oluşturan kullanıcıyı firma_sahibi yapar.
  /// SECURITY DEFINER RPC fonksiyonu kullanarak RLS'yi bypass eder.
  static Future<String> firmaOlustur({
    required String firmaAdi,
    required String firmaKodu,
    Map<String, dynamic>? firmaBilgileri,
    required List<String> secilenModuller,
    required List<String> secilenUretimDallari,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Oturum açık değil');

    final rpcData = {
      'firma_adi': firmaAdi,
      'firma_kodu': firmaKodu,
      if (firmaBilgileri != null) ...firmaBilgileri,
      'secilen_uretim_dallari': secilenUretimDallari,
    };

    final response = await _client.rpc(
      'create_firma_with_owner',
      params: {'p_data': rpcData},
    );

    final firmaId = response['firma_id'] as String;

    // TenantManager'ı güncelle
    await TenantManager.instance.firmaSecimi(firmaId);
    await TenantManager.instance.kullaniciFirmalariniYukle(userId);

    return firmaId;
  }

  /// Tüm modülleri firmaya atar (deneme döneminde tüm modüller dahil).
  static Future<void> tumModulleriAta(String firmaId) async {
    final moduller = await _client
        .from(DbTables.modulTanimlari)
        .select('id, modul_kodu');

    final kayitlar = (moduller as List).map((m) => {
      'firma_id': firmaId,
      'modul_id': m['id'],
      'aktif': true,
    }).toList();

    if (kayitlar.isNotEmpty) {
      await _client.from(DbTables.firmaModulleri).upsert(kayitlar);
    }
  }

  /// Modülleri firmaya atar.
  static Future<void> modulleriAta(String firmaId, List<String> modulKodlari) async {
    if (modulKodlari.isEmpty) return;

    // Modül ID'lerini çek
    final moduller = await _client
        .from(DbTables.modulTanimlari)
        .select('id, modul_kodu')
        .inFilter('modul_kodu', modulKodlari);

    final kayitlar = (moduller as List).map((m) => {
      'firma_id': firmaId,
      'modul_id': m['id'],
      'aktif': true,
    }).toList();

    if (kayitlar.isNotEmpty) {
      await _client.from(DbTables.firmaModulleri).upsert(kayitlar);
    }
  }

  /// Üretim dallarını firmaya atar.
  static Future<void> uretimDallariniAta(String firmaId, List<String> dalKodlari) async {
    if (dalKodlari.isEmpty) return;

    final dallar = await _client
        .from(DbTables.uretimModulleri)
        .select('id, modul_kodu')
        .inFilter('modul_kodu', dalKodlari);

    final kayitlar = (dallar as List).map((d) => {
      'firma_id': firmaId,
      'uretim_modul_id': d['id'],
      'aktif': true,
    }).toList();

    if (kayitlar.isNotEmpty) {
      await _client.from(DbTables.firmaUretimModulleri).upsert(kayitlar);
    }
  }

  /// Firma kodunun kullanılabilir olup olmadığını kontrol eder.
  static Future<bool> firmaKoduMusait(String firmaKodu) async {
    final response = await _client
        .from(DbTables.firmalar)
        .select('id')
        .eq('firma_kodu', firmaKodu)
        .maybeSingle();
    return response == null;
  }

  /// Tüm modül tanımlarını getirir.
  static Future<List<Map<String, dynamic>>> modulTanimlariniGetir() async {
    final response = await _client
        .from(DbTables.modulTanimlari)
        .select()
        .eq('aktif', true)
        .order('sira_no');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Tüm üretim dalı tanımlarını getirir.
  static Future<List<Map<String, dynamic>>> uretimDallariniGetir() async {
    final response = await _client
        .from(DbTables.uretimModulleri)
        .select()
        .eq('aktif', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ─────────────────────────────────────────
  // DAVET SİSTEMİ
  // ─────────────────────────────────────────

  /// Kullanıcıyı firmaya davet eder.
  static Future<String> kullaniciDavetEt({
    required String email,
    String rol = 'kullanici',
  }) async {
    final firmaId = TenantManager.instance.requireFirmaId;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Oturum açık değil');

    final davetKodu = _davetKoduOlustur();

    await _client.from(DbTables.firmaDavetleri).insert({
      'firma_id': firmaId,
      'davet_eden_id': userId,
      'email': email,
      'rol': rol,
      'davet_kodu': davetKodu,
      'durum': 'beklemede',
    });

    return davetKodu;
  }

  /// Davet kodunu doğrular ve bilgilerini döndürür.
  static Future<Map<String, dynamic>?> davetDogrula(String davetKodu) async {
    final response = await _client
        .from(DbTables.firmaDavetleri)
        .select('*, firmalar(firma_adi, firma_kodu)')
        .eq('davet_kodu', davetKodu)
        .eq('durum', 'beklemede')
        .gt('gecerlilik_tarihi', DateTime.now().toIso8601String())
        .maybeSingle();
    return response;
  }

  /// Daveti kabul eder ve kullanıcıyı firmaya ekler.
  static Future<void> davetKabulEt(String davetKodu) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Oturum açık değil');

    final davet = await davetDogrula(davetKodu);
    if (davet == null) throw Exception('Geçersiz veya süresi dolmuş davet kodu');

    // Kullanıcıyı firmaya ekle
    await _client.from(DbTables.firmaKullanicilari).insert({
      'firma_id': davet['firma_id'],
      'user_id': userId,
      'rol': davet['rol'] ?? 'kullanici',
      'aktif': true,
      'katilim_tarihi': DateTime.now().toIso8601String(),
    });

    // Daveti kabul edildi olarak işaretle
    await _client
        .from(DbTables.firmaDavetleri)
        .update({'durum': 'kabul_edildi'})
        .eq('id', davet['id']);

    // TenantManager'ı güncelle
    await TenantManager.instance.kullaniciFirmalariniYukle(userId);
    await TenantManager.instance.firmaSecimi(davet['firma_id']);
  }

  /// Rastgele 8 karakterli davet kodu üretir.
  static String _davetKoduOlustur() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
