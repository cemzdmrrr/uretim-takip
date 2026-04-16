import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/app_logger.dart';
import 'package:uretim_takip/config/asama_registry.dart';

/// Aktif firma bağlamını yöneten singleton.
///
/// Hem static hem instance servislerden erişilebilir:
/// ```dart
/// final firmaId = TenantManager.instance.firmaId;
/// ```
class TenantManager {
  TenantManager._();
  static final TenantManager instance = TenantManager._();
  static const _setActiveFirmaRpc = 'set_active_firma';

  String? _firmaId;
  Map<String, dynamic>? _firmaDetay;
  List<Map<String, dynamic>> _kullaniciFirmalari = [];
  List<String> _aktifModuller = [];
  List<String> _aktifUretimDallari = [];
  Map<String, dynamic>? _aktifAbonelik;
  String? _firmaRol;
  List<String> _yetkiler = [];

  String? get firmaId => _firmaId;
  Map<String, dynamic>? get firmaDetay => _firmaDetay;
  String get firmaAdi => _firmaDetay?['firma_adi'] ?? '';
  List<Map<String, dynamic>> get kullaniciFirmalari =>
      List.unmodifiable(_kullaniciFirmalari);
  List<String> get aktifModuller => List.unmodifiable(_aktifModuller);
  List<String> get aktifUretimDallari => List.unmodifiable(_aktifUretimDallari);
  bool get firmaSecildi => _firmaId != null;
  Map<String, dynamic>? get aktifAbonelik => _aktifAbonelik;
  String? get firmaRol => _firmaRol;
  List<String> get yetkiler => List.unmodifiable(_yetkiler);

  /// Firma sahibi veya firma admini mi?
  bool get isFirmaAdmin =>
      _firmaRol == 'firma_sahibi' || _firmaRol == 'firma_admin';

  /// Modül + yetki kontrolü.
  bool yetkiVarMi(String modulKodu, String yetki) {
    if (isFirmaAdmin) return true;
    if (_yetkiler.contains('*')) return true;
    return _yetkiler.contains('$modulKodu:$yetki');
  }

  /// Modüle okuma erişimi var mı?
  bool modulErisimVarMi(String modulKodu) => yetkiVarMi(modulKodu, 'okuma');

  /// Abonelik geçerli mi (aktif veya deneme süresi devam ediyor)?
  bool get abonelikGecerliMi {
    if (_aktifAbonelik == null) return false;
    final durum = _aktifAbonelik!['durum'] as String?;
    if (durum == 'aktif') return true;
    if (durum == 'deneme') {
      final denemeBitisStr = _aktifAbonelik!['deneme_bitis']?.toString();
      if (denemeBitisStr == null) return false;
      final denemeBitis = DateTime.tryParse(denemeBitisStr);
      return denemeBitis != null && DateTime.now().isBefore(denemeBitis);
    }
    return false;
  }

  /// Firma ID'yi zorunlu olarak döndürür; seçilmemişse hata fırlatır.
  String get requireFirmaId {
    final id = _firmaId;
    if (id == null) throw StateError('Firma seçilmemiş');
    return id;
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Kullanıcının erişebildiği firmaları yükler.
  Future<void> kullaniciFirmalariniYukle(String userId) async {
    try {
      final response = await _client
          .from(DbTables.firmaKullanicilari)
          .select(
              'firma_id, rol, firmalar(id, firma_adi, firma_kodu, logo_url, aktif)')
          .eq('user_id', userId)
          .eq('aktif', true);

      _kullaniciFirmalari = List<Map<String, dynamic>>.from(response);

      final aktifFirmaId = await _aktifFirmaSeciminiGetir();
      if (aktifFirmaId != null &&
          _kullaniciFirmalari.any((item) =>
              item['firma_id'] == aktifFirmaId ||
              item['firmalar']?['id'] == aktifFirmaId)) {
        await firmaSecimi(aktifFirmaId, persistSelection: false);
        return;
      }

      // Tek firma varsa otomatik seç
      if (_kullaniciFirmalari.length == 1) {
        final firmaData = _kullaniciFirmalari.first['firmalar'];
        if (firmaData != null) {
          await firmaSecimi(firmaData['id']);
        }
      }
    } catch (e) {
      AppLogger.error('TenantManager', 'Firma listesi yükleme hatası', e);
      _kullaniciFirmalari = [];
    }
  }

  /// Aktif firmayı değiştirir ve modülleri yükler.
  Future<void> firmaSecimi(String firmaId,
      {bool persistSelection = true}) async {
    final oncekiFirmaId = _firmaId;
    final oncekiFirmaDetay =
        _firmaDetay == null ? null : Map<String, dynamic>.from(_firmaDetay!);
    final oncekiAktifModuller = List<String>.from(_aktifModuller);
    final oncekiAktifUretimDallari = List<String>.from(_aktifUretimDallari);
    final oncekiAktifAbonelik = _aktifAbonelik == null
        ? null
        : Map<String, dynamic>.from(_aktifAbonelik!);
    final oncekiFirmaRol = _firmaRol;
    final oncekiYetkiler = List<String>.from(_yetkiler);

    if (persistSelection) {
      await _aktifFirmaSeciminiKaydet(firmaId);
    }

    _firmaId = firmaId;

    // Firma detaylarını yükle
    try {
      final response = await _client
          .from(DbTables.firmalar)
          .select()
          .eq('id', firmaId)
          .single();
      _firmaDetay = response;
    } catch (e) {
      AppLogger.error('TenantManager', 'Firma detay yükleme hatası', e);
      _firmaId = oncekiFirmaId;
      _firmaDetay = oncekiFirmaDetay;
      _aktifModuller = oncekiAktifModuller;
      _aktifUretimDallari = oncekiAktifUretimDallari;
      _aktifAbonelik = oncekiAktifAbonelik;
      _firmaRol = oncekiFirmaRol;
      _yetkiler = oncekiYetkiler;
      rethrow;
    }

    await _modulleriYukle();
    await AsamaRegistry.yukle();
    await _abonelikYukle();
    await _firmaRolYukle();
  }

  Future<void> _aktifFirmaSeciminiKaydet(String firmaId) async {
    try {
      await _client.rpc(_setActiveFirmaRpc, params: {'p_firma_id': firmaId});
    } catch (e) {
      AppLogger.error(
          'TenantManager', 'Aktif firma seçimi doğrulama hatası', e);
      rethrow;
    }
  }

  Future<String?> _aktifFirmaSeciminiGetir() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DbTables.kullaniciAktifFirma)
          .select('firma_id')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['firma_id'] as String?;
    } catch (e) {
      AppLogger.error(
        'TenantManager',
        'Aktif firma kaydı okuma hatası',
        e,
      );
      return null;
    }
  }

  Future<void> _modulleriYukle() async {
    if (_firmaId == null) return;

    try {
      // Aktif modülleri yükle
      final modulResponse = await _client
          .from(DbTables.firmaModulleri)
          .select('modul_tanimlari(modul_kodu)')
          .eq('firma_id', _firmaId!)
          .eq('aktif', true);

      _aktifModuller = (modulResponse as List)
          .map((m) => m['modul_tanimlari']?['modul_kodu'] as String?)
          .where((k) => k != null)
          .cast<String>()
          .toList();

      // Aktif üretim dallarını yükle
      final uretimResponse = await _client
          .from(DbTables.firmaUretimModulleri)
          .select('uretim_modulleri(modul_kodu)')
          .eq('firma_id', _firmaId!)
          .eq('aktif', true);

      _aktifUretimDallari = (uretimResponse as List)
          .map((m) => m['uretim_modulleri']?['modul_kodu'] as String?)
          .where((k) => k != null)
          .cast<String>()
          .toList();
    } catch (e) {
      AppLogger.error('TenantManager', 'Modül yükleme hatası', e);
      _aktifModuller = [];
      _aktifUretimDallari = [];
    }
  }

  Future<void> _abonelikYukle() async {
    if (_firmaId == null) return;
    try {
      final response = await _client
          .from(DbTables.firmaAbonelikleri)
          .select('*, abonelik_planlari(*)')
          .eq('firma_id', _firmaId!)
          .inFilter('durum', ['aktif', 'deneme', 'odeme_bekleniyor'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      _aktifAbonelik = response;
    } catch (e) {
      AppLogger.error('TenantManager', 'Abonelik yükleme hatası', e);
      _aktifAbonelik = null;
    }
  }

  Future<void> _firmaRolYukle() async {
    if (_firmaId == null) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _client
          .from(DbTables.firmaKullanicilari)
          .select('rol')
          .eq('firma_id', _firmaId!)
          .eq('user_id', userId)
          .eq('aktif', true)
          .maybeSingle();
      _firmaRol = response?['rol'] as String?;
    } catch (e) {
      AppLogger.error('TenantManager', 'Firma rolü yükleme hatası', e);
      _firmaRol = null;
    }

    // firma_sahibi / firma_admin ise tüm yetkiler
    if (isFirmaAdmin) {
      _yetkiler = ['*'];
      return;
    }

    // Diğer roller için yetki_tanimlari tablosundan
    if (_firmaRol == null) {
      _yetkiler = [];
      return;
    }

    try {
      final response = await _client
          .from(DbTables.yetkiTanimlari)
          .select('modul_kodu, yetki')
          .or('firma_id.eq.$_firmaId,firma_id.is.null')
          .eq('rol', _firmaRol!)
          .eq('aktif', true);

      _yetkiler = (response as List)
          .map((r) => '${r['modul_kodu']}:${r['yetki']}')
          .toList();
    } catch (e) {
      AppLogger.error('TenantManager', 'Yetki yükleme hatası', e);
      _yetkiler = [];
    }
  }

  /// Belirli bir modülün aktif olup olmadığını kontrol eder.
  bool modulAktifMi(String modulKodu) => _aktifModuller.contains(modulKodu);

  /// Belirli bir üretim dalının aktif olup olmadığını kontrol eder.
  bool uretimDaliAktifMi(String dalKodu) =>
      _aktifUretimDallari.contains(dalKodu);

  /// Oturum kapatıldığında tenant verilerini temizler.
  void temizle() {
    _firmaId = null;
    _firmaDetay = null;
    _kullaniciFirmalari = [];
    _aktifModuller = [];
    _aktifUretimDallari = [];
    _aktifAbonelik = null;
    _firmaRol = null;
    _yetkiler = [];
    AsamaRegistry.cacheTemizle();
  }

  /// Test ortamında iç durumu ayarlamak için kullanılır.
  @visibleForTesting
  void testDurumAyarla({
    String? firmaId,
    Map<String, dynamic>? firmaDetay,
    List<Map<String, dynamic>>? kullaniciFirmalari,
    List<String>? aktifModuller,
    List<String>? aktifUretimDallari,
    Map<String, dynamic>? aktifAbonelik,
    String? firmaRol,
    List<String>? yetkiler,
  }) {
    _firmaId = firmaId;
    _firmaDetay = firmaDetay;
    if (kullaniciFirmalari != null) _kullaniciFirmalari = kullaniciFirmalari;
    if (aktifModuller != null) _aktifModuller = aktifModuller;
    if (aktifUretimDallari != null) _aktifUretimDallari = aktifUretimDallari;
    _aktifAbonelik = aktifAbonelik;
    _firmaRol = firmaRol;
    if (yetkiler != null) _yetkiler = yetkiler;
  }
}
