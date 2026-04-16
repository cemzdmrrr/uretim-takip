class RoleUtils {
  RoleUtils._();

  static const String adminRole = 'admin';
  static const String standardUserRole = 'kullanici';

  static const Map<String, String> _userRoleAliases = {
    'admin': 'admin',
    'user': 'kullanici',
    'kullanici': 'kullanici',
    'viewer': 'viewer',
    'yonetici': 'yonetici',
    'personel': 'personel',
    'firma_admin': 'firma_admin',
    'firma_sahibi': 'firma_sahibi',
    'dokuma': 'dokumaci',
    'dokumaci': 'dokumaci',
    'konfeksiyon': 'konfeksiyoncu',
    'konfeksiyoncu': 'konfeksiyoncu',
    'kalite_kontrol': 'kalite_kontrol',
    'sofor': 'sofor',
    'sevkiyat': 'sevkiyat',
    'muhasebeci': 'muhasebeci',
    'depo': 'depocu',
    'depocu': 'depocu',
    'utu': 'utu_paket',
    'utu_paket': 'utu_paket',
    'paketleme': 'utu_paket',
    'ilik_dugme': 'ilik_dugme',
    'yikama': 'yikama',
    'nakis': 'nakis',
  };

  static const Map<String, String> _dashboardRoleAliases = {
    'admin': 'admin',
    'user': 'kullanici',
    'kullanici': 'kullanici',
    'personel': 'personel',
    'dokuma': 'dokuma',
    'dokumaci': 'dokuma',
    'konfeksiyon': 'konfeksiyon',
    'konfeksiyoncu': 'konfeksiyon',
    'kalite_kontrol': 'kalite_kontrol',
    'sofor': 'sofor',
    'sevkiyat': 'sevkiyat',
    'depo': 'depo',
    'depocu': 'depo',
    'utu': 'utu_paket',
    'utu_paket': 'utu_paket',
    'paketleme': 'utu_paket',
    'ilik_dugme': 'ilik_dugme',
    'yikama': 'yikama',
    'nakis': 'nakis',
  };

  static String? normalizeUserRole(String? role) {
    if (role == null) return null;
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _userRoleAliases[normalized] ?? normalized;
  }

  static String? normalizeDashboardRole(String? role) {
    if (role == null) return null;
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _dashboardRoleAliases[normalized] ?? normalized;
  }

  static bool sameUserRole(String? left, String? right) {
    return normalizeUserRole(left) == normalizeUserRole(right);
  }

  static bool sameDashboardRole(String? left, String? right) {
    return normalizeDashboardRole(left) == normalizeDashboardRole(right);
  }

  static bool isAdmin(String? role) => sameUserRole(role, adminRole);

  static bool isStandardUser(String? role) =>
      sameUserRole(role, standardUserRole);

  static bool isAnyUserRole(String? role, Iterable<String> candidates) {
    final normalizedRole = normalizeUserRole(role);
    if (normalizedRole == null) return false;
    return candidates
        .map(normalizeUserRole)
        .whereType<String>()
        .contains(normalizedRole);
  }
}
