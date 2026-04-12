import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_logger.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Firma bazlı kullanıcı rolleri ve modül-yetki yönetimi servisi.
///
/// Yetki hiyerarşisi:
/// - platform_admin → Tüm sistemi yönetir
/// - firma_sahibi  → Firmayı oluşturan, tam yetki
/// - firma_admin   → Firma yöneticisi
/// - yonetici      → Departman yöneticisi
/// - kullanici     → Standart kullanıcı
/// - personel      → Sadece kendi bilgilerini görür
/// - (özel roller) → dokumaci, konfeksiyoncu, kalite_kontrol, vb.
class YetkiService {
  static final _client = Supabase.instance.client;

  static String get _firmaId => TenantManager.instance.requireFirmaId;

  // ── Rol Tanımları ────────────────────────────────────────

  /// Firma seviyesi roller (hiyerarşi sırasıyla).
  static const firmaRolleri = [
    'firma_sahibi',
    'firma_admin',
    'yonetici',
    'kullanici',
    'personel',
  ];

  /// Özel (üretim dalına göre) roller.
  static const ozelRoller = [
    'dokumaci',
    'konfeksiyoncu',
    'kalite_kontrol',
    'sofor',
    'muhasebeci',
    'depocu',
  ];

  /// Tüm geçerli roller.
  static List<String> get tumRoller => [...firmaRolleri, ...ozelRoller];

  /// Rol → okunabilir etiket haritası.
  static const rolEtiketleri = {
    'firma_sahibi': 'Firma Sahibi',
    'firma_admin': 'Firma Yöneticisi',
    'yonetici': 'Yönetici',
    'kullanici': 'Kullanıcı',
    'personel': 'Personel',
    'dokumaci': 'Dokumacı',
    'konfeksiyoncu': 'Konfeksiyoncu',
    'kalite_kontrol': 'Kalite Kontrol',
    'sofor': 'Şoför',
    'muhasebeci': 'Muhasebeci',
    'depocu': 'Depocu',
  };

  /// Yetki türleri.
  static const yetkiTurleri = ['okuma', 'yazma', 'silme', 'yonetim', 'export'];

  // ── Kullanıcının Firma Rolü ──────────────────────────────

  /// Aktif firmadaki rolünü getirir.
  static Future<String?> kullaniciFirmaRolGetir() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DbTables.firmaKullanicilari)
          .select('rol')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId)
          .eq('aktif', true)
          .maybeSingle();

      return response?['rol'] as String?;
    } catch (e) {
      AppLogger.error('YetkiService', 'Firma rolü getirme hatası', e);
      return null;
    }
  }

  /// Kullanıcının firma bazlı yetkilerini yükler.
  /// Döndürülen format: ['uretim:okuma', 'uretim:yazma', 'finans:okuma', ...]
  static Future<List<String>> kullaniciYetkileriniYukle() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Kullanıcının firmadaki rolünü al
      final firmaRol = await kullaniciFirmaRolGetir();
      if (firmaRol == null) return [];

      // firma_sahibi ve firma_admin tam yetkili
      if (firmaRol == 'firma_sahibi' || firmaRol == 'firma_admin') {
        return ['*']; // Özel joker — tüm yetkiler
      }

      // Önce firmaya özel yetkileri sorgula, yoksa platform varsayılanını al
      final response = await _client
          .from(DbTables.yetkiTanimlari)
          .select('modul_kodu, yetki')
          .or('firma_id.eq.$_firmaId,firma_id.is.null')
          .eq('rol', firmaRol)
          .eq('aktif', true);

      return (response as List)
          .map((r) => '${r['modul_kodu']}:${r['yetki']}')
          .toList();
    } catch (e) {
      AppLogger.error('YetkiService', 'Yetki yükleme hatası', e);
      return [];
    }
  }

  // ── Yetki Kontrolleri ────────────────────────────────────

  /// Belirli modülde belirli yetkisi var mı?
  static bool yetkiVarMi(List<String> yetkiler, String modulKodu, String yetki) {
    if (yetkiler.contains('*')) return true;
    return yetkiler.contains('$modulKodu:$yetki');
  }

  /// Modüle okuma erişimi var mı?
  static bool modulErisimVarMi(List<String> yetkiler, String modulKodu) {
    return yetkiVarMi(yetkiler, modulKodu, 'okuma');
  }

  /// Modüle yazma erişimi var mı?
  static bool yazmaYetkisiVarMi(List<String> yetkiler, String modulKodu) {
    return yetkiVarMi(yetkiler, modulKodu, 'yazma');
  }

  /// Yönetim yetkisi var mı?
  static bool yonetimYetkisiVarMi(List<String> yetkiler, String modulKodu) {
    return yetkiVarMi(yetkiler, modulKodu, 'yonetim');
  }

  // ── Firma Kullanıcı Yönetimi ────────────────────────────

  /// Firmadaki tüm kullanıcıları detaylı listeler.
  static Future<List<Map<String, dynamic>>> firmaKullanicilariGetir() async {
    final response = await _client
        .rpc('firma_kullanicilari_detay', params: {'p_firma_id': _firmaId});
    return List<Map<String, dynamic>>.from(response);
  }

  /// Kullanıcının rolünü değiştirir (firma_kullanicilari tablosu).
  static Future<void> kullaniciRolDegistir({
    required String firmaKullaniciId,
    required String yeniRol,
  }) async {
    if (!tumRoller.contains(yeniRol)) {
      throw ArgumentError('Geçersiz rol: $yeniRol');
    }

    await _client
        .from(DbTables.firmaKullanicilari)
        .update({'rol': yeniRol})
        .eq('id', firmaKullaniciId)
        .eq('firma_id', _firmaId);
  }

  /// Kullanıcıyı firma içinde aktif/pasif yapar.
  static Future<void> kullaniciAktifPasif({
    required String firmaKullaniciId,
    required bool aktif,
  }) async {
    await _client
        .from(DbTables.firmaKullanicilari)
        .update({'aktif': aktif})
        .eq('id', firmaKullaniciId)
        .eq('firma_id', _firmaId);
  }

  /// Kullanıcıyı firmadan çıkarır.
  static Future<void> kullaniciCikar(String firmaKullaniciId) async {
    await _client
        .from(DbTables.firmaKullanicilari)
        .delete()
        .eq('id', firmaKullaniciId)
        .eq('firma_id', _firmaId);
  }

  // ── Firma Özel Yetki Yönetimi ───────────────────────────

  /// Firmaya özel yetki tanımlarını getirir.
  static Future<List<Map<String, dynamic>>> firmaYetkiTanimlariGetir() async {
    final response = await _client
        .from(DbTables.yetkiTanimlari)
        .select()
        .eq('firma_id', _firmaId)
        .order('rol')
        .order('modul_kodu');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Firmaya özel yetki ekler/günceller.
  static Future<void> yetkiTanimla({
    required String rol,
    required String modulKodu,
    required String yetki,
    bool aktif = true,
  }) async {
    await _client.from(DbTables.yetkiTanimlari).upsert(
      {
        'firma_id': _firmaId,
        'rol': rol,
        'modul_kodu': modulKodu,
        'yetki': yetki,
        'aktif': aktif,
      },
    );
  }

  /// Platform varsayılan yetkilerini getirir (firma_id = null).
  static Future<List<Map<String, dynamic>>> varsayilanYetkilerGetir(
      String rol) async {
    final response = await _client
        .from(DbTables.yetkiTanimlari)
        .select('modul_kodu, yetki, aktif')
        .isFilter('firma_id', null)
        .eq('rol', rol)
        .order('modul_kodu');

    return List<Map<String, dynamic>>.from(response);
  }
}
