import 'package:flutter/foundation.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Widget ağacında firma bağlamını paylaşan ChangeNotifier.
///
/// TenantManager singleton'ı üzerinden çalışır, UI güncellemeleri sağlar.
///
/// Kullanım:
/// ```dart
/// final tenant = context.read<TenantProvider>();
/// if (tenant.modulAktifMi('finans')) { ... }
/// ```
class TenantProvider extends ChangeNotifier {
  final _manager = TenantManager.instance;

  String? get firmaId => _manager.firmaId;
  String get firmaAdi => _manager.firmaAdi;
  Map<String, dynamic>? get firmaDetay => _manager.firmaDetay;
  List<Map<String, dynamic>> get kullaniciFirmalari =>
      _manager.kullaniciFirmalari;
  List<String> get aktifModuller => _manager.aktifModuller;
  List<String> get aktifUretimDallari => _manager.aktifUretimDallari;
  bool get firmaSecildi => _manager.firmaSecildi;
  bool get cokluFirma => _manager.kullaniciFirmalari.length > 1;
  Map<String, dynamic>? get aktifAbonelik => _manager.aktifAbonelik;
  bool get abonelikGecerliMi => _manager.abonelikGecerliMi;
  String? get firmaRol => _manager.firmaRol;
  List<String> get yetkiler => _manager.yetkiler;
  bool get isFirmaAdmin => _manager.isFirmaAdmin;

  /// Kullanıcının firmalarını yükler ve UI'ı günceller.
  Future<void> kullaniciFirmalariniYukle(String userId) async {
    await _manager.kullaniciFirmalariniYukle(userId);
    notifyListeners();
  }

  /// Aktif firmayı değiştir ve UI'ı güncelle.
  Future<void> firmaSecimi(String firmaId) async {
    await _manager.firmaSecimi(firmaId);
    notifyListeners();
  }

  /// Modül aktif mi kontrol et.
  bool modulAktifMi(String modulKodu) => _manager.modulAktifMi(modulKodu);

  /// Üretim dalı aktif mi kontrol et.
  bool uretimDaliAktifMi(String dalKodu) =>
      _manager.uretimDaliAktifMi(dalKodu);

  /// Modül + yetki kontrol et (firma rol bazlı).
  bool yetkiVarMi(String modulKodu, String yetki) =>
      _manager.yetkiVarMi(modulKodu, yetki);

  /// Modüle okuma erişimi var mı?
  bool modulErisimVarMi(String modulKodu) =>
      _manager.modulErisimVarMi(modulKodu);

  /// Oturumu kapatırken temizle.
  void temizle() {
    _manager.temizle();
    notifyListeners();
  }
}
