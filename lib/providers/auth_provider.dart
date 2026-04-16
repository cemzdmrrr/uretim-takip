import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/secure_storage.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/yetki_service.dart';
import 'package:uretim_takip/utils/role_utils.dart';

/// Merkezi kimlik doğrulama ve kullanıcı durumu yönetimi.
///
/// Platform rolü (user_roles) ve firma rolü (firma_kullanicilari)
/// ayrı ayrı takip edilir. Modül-bazlı yetkiler firma rolüne göre yüklenir.
///
/// Kullanım:
/// ```dart
/// final auth = context.read<AuthProvider>();
/// if (auth.isAdmin) { ... }
/// if (auth.yetkiVarMi('finans', 'yazma')) { ... }
/// ```
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _role; // Platform rolü (user_roles tablosu)
  String? _firmaRol; // Aktif firmadaki rol (firma_kullanicilari)
  List<String> _yetkiler = []; // Modül:yetki listesi
  bool _loading = true;

  User? get user => _user;
  String? get role => _role;
  String? get firmaRol => _firmaRol;
  List<String> get yetkiler => List.unmodifiable(_yetkiler);
  String get userId => _user?.id ?? '';
  String get userEmail => _user?.email ?? '';
  bool get isLoggedIn => _user != null;
  bool get isAdmin => RoleUtils.isAdmin(_role);
  bool get isLoading => _loading;

  /// Firma sahibi veya firma admini mi?
  bool get isFirmaAdmin =>
      _firmaRol == 'firma_sahibi' || _firmaRol == 'firma_admin';

  /// Firma sahibi mi?
  bool get isFirmaSahibi => _firmaRol == 'firma_sahibi';

  /// Belirtilen rollerden birine sahip mi (admin dahil)
  bool hasRole(List<String> roles) {
    if (_role == null) return false;
    if (isAdmin) return true;
    return roles.any((role) => RoleUtils.sameUserRole(_role, role));
  }

  /// Belirtilen role sahip mi (admin hariç)
  bool hasExactRole(String role) => RoleUtils.sameUserRole(_role, role);

  /// Modül + yetki bazlı kontrol.
  /// firma_sahibi ve firma_admin tüm yetkilere sahiptir.
  bool yetkiVarMi(String modulKodu, String yetki) {
    if (isAdmin || isFirmaAdmin) return true;
    return YetkiService.yetkiVarMi(_yetkiler, modulKodu, yetki);
  }

  /// Modüle okuma erişimi var mı?
  bool modulErisimVarMi(String modulKodu) {
    if (isAdmin || isFirmaAdmin) return true;
    return YetkiService.modulErisimVarMi(_yetkiler, modulKodu);
  }

  /// Uygulama başlatıldığında veya oturum değiştiğinde çağrılır.
  Future<void> initialize() async {
    final client = Supabase.instance.client;
    _user = client.auth.currentUser;

    if (_user != null) {
      await _fetchRole();
    }

    _loading = false;
    notifyListeners();

    // Auth durumu değişikliklerini dinle
    client.auth.onAuthStateChange.listen((data) {
      final newUser = data.session?.user;
      if (newUser?.id != _user?.id) {
        _user = newUser;
        if (_user != null) {
          _fetchRole();
        } else {
          _role = null;
          _firmaRol = null;
          _yetkiler = [];
          notifyListeners();
        }
      }
    });
  }

  Future<void> _fetchRole() async {
    try {
      final response = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', _user!.id)
          .eq('aktif', true)
          .maybeSingle();

      _role = response?['role'];
    } catch (e) {
      debugPrint('Rol getirme hatası: $e');
      _role = null;
    }
    notifyListeners();
  }

  /// Firma seçildikten sonra firma rolü ve yetkilerini yükler.
  Future<void> firmaYetkileriniYukle() async {
    try {
      _firmaRol = await YetkiService.kullaniciFirmaRolGetir();
      _yetkiler = await YetkiService.kullaniciYetkileriniYukle();
    } catch (e) {
      debugPrint('Firma yetkileri yükleme hatası: $e');
      _firmaRol = null;
      _yetkiler = [];
    }
    notifyListeners();
  }

  /// Rolü yeniden yükler (yetki değişikliğinden sonra).
  Future<void> refreshRole() async {
    if (_user == null) return;
    await _fetchRole();
    // Firma seçili ise firma yetkilerini de yenile
    if (TenantManager.instance.firmaSecildi) {
      await firmaYetkileriniYukle();
    }
  }

  /// Oturumu kapatır.
  Future<void> signOut() async {
    TenantManager.instance.temizle();
    await Supabase.instance.client.auth.signOut();
    await SecureCredentialStorage.clear();
    _user = null;
    _role = null;
    _firmaRol = null;
    _yetkiler = [];
    notifyListeners();
  }

  /// Test ortamında iç durumu ayarlamak için kullanılır.
  @visibleForTesting
  void testDurumAyarla({
    String? role,
    String? firmaRol,
    List<String>? yetkiler,
    bool loading = false,
  }) {
    _role = role;
    _firmaRol = firmaRol;
    if (yetkiler != null) _yetkiler = yetkiler;
    _loading = loading;
  }
}
