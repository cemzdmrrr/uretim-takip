import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/utils/role_utils.dart';

class UserRoleService {
  UserRoleService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static const List<String> _rolePriority = [
    'admin',
    'firma_sahibi',
    'firma_admin',
    'yonetici',
    'personel',
    'kalite_kontrol',
    'sevkiyat',
    'depocu',
    'dokumaci',
    'konfeksiyoncu',
    'nakis',
    'yikama',
    'utu_paket',
    'ilik_dugme',
    'sofor',
    'muhasebeci',
    'kullanici',
  ];

  static const Set<String> _userRolesTablosundaDesteklenenRoller = {
    'admin',
    'dokumaci',
    'konfeksiyoncu',
    'kalite_kontrol',
    'sevkiyat',
    'sofor',
    'muhasebeci',
    'depocu',
    'nakis',
    'yikama',
    'utu_paket',
    'ilik_dugme',
  };

  static String? get _aktifFirmaId {
    try {
      return TenantManager.instance.requireFirmaId;
    } catch (_) {
      return TenantManager.instance.firmaId;
    }
  }

  static String _normalizedOrOriginal(String role) {
    return RoleUtils.normalizeUserRole(role) ?? role.trim().toLowerCase();
  }

  static Future<String?> kullaniciFirmaRolunuGetir({
    String? userId,
    String? firmaId,
    SupabaseClient? client,
  }) async {
    final hedefUserId = userId ?? _client.auth.currentUser?.id;
    final hedefFirmaId = firmaId ?? _aktifFirmaId;
    if (hedefUserId == null || hedefFirmaId == null) return null;

    final db = client ?? _client;
    try {
      final response = await db
          .from(DbTables.firmaKullanicilari)
          .select('rol')
          .eq('firma_id', hedefFirmaId)
          .eq('user_id', hedefUserId)
          .eq('aktif', true)
          .maybeSingle();
      return RoleUtils.normalizeUserRole(response?['rol']?.toString());
    } catch (_) {
      return null;
    }
  }

  static Future<Set<String>> kullaniciOperasyonRolleriniGetir({
    String? userId,
    String? firmaId,
    SupabaseClient? client,
  }) async {
    final hedefUserId = userId ?? _client.auth.currentUser?.id;
    if (hedefUserId == null) return {};

    final hedefFirmaId = firmaId ?? _aktifFirmaId;
    final db = client ?? _client;

    Future<List<dynamic>> sorgu({bool withFirma = true}) async {
      final query = db
          .from(DbTables.userRoles)
          .select('role, aktif, firma_id')
          .eq('user_id', hedefUserId);
      if (withFirma && hedefFirmaId != null) {
        return await query.or('firma_id.is.null,firma_id.eq.$hedefFirmaId');
      }
      return await query;
    }

    try {
      final rows = await sorgu();
      return rows
          .where((row) => row['aktif'] != false)
          .map((row) => RoleUtils.normalizeUserRole(row['role']?.toString()))
          .where((rol) => _userRolesTablosundaDesteklenenRoller.contains(rol))
          .whereType<String>()
          .toSet();
    } catch (_) {
      try {
        final rows = await db
            .from(DbTables.userRoles)
            .select('role')
            .eq('user_id', hedefUserId);
        return (rows as List)
            .map((row) => RoleUtils.normalizeUserRole(row['role']?.toString()))
            .where((rol) => _userRolesTablosundaDesteklenenRoller.contains(rol))
            .whereType<String>()
            .toSet();
      } catch (_) {
        return {};
      }
    }
  }

  static Future<Set<String>> kullaniciTumRolleriniGetir({
    String? userId,
    String? firmaId,
    SupabaseClient? client,
  }) async {
    final operasyonRolleri = await kullaniciOperasyonRolleriniGetir(
      userId: userId,
      firmaId: firmaId,
      client: client,
    );
    final firmaRolu = await kullaniciFirmaRolunuGetir(
      userId: userId,
      firmaId: firmaId,
      client: client,
    );
    if (firmaRolu != null && firmaRolu.isNotEmpty) {
      operasyonRolleri.add(firmaRolu);
    }
    return operasyonRolleri;
  }

  static bool isFirmaAdminRolu(String? rol) {
    return rol == 'admin' || rol == 'firma_admin' || rol == 'firma_sahibi';
  }

  static String birincilRolSec(
    Iterable<String> roller, {
    String? firmaRolu,
  }) {
    final set = roller.map(_normalizedOrOriginal).toSet();
    if (firmaRolu != null) {
      set.add(_normalizedOrOriginal(firmaRolu));
    }

    for (final rol in _rolePriority) {
      if (set.contains(rol)) return rol;
    }
    return set.isNotEmpty ? set.first : RoleUtils.standardUserRole;
  }

  static Future<String> kullaniciBirincilRolunuGetir({
    String? userId,
    String? firmaId,
    SupabaseClient? client,
  }) async {
    final firmaRolu = await kullaniciFirmaRolunuGetir(
      userId: userId,
      firmaId: firmaId,
      client: client,
    );
    final roller = await kullaniciTumRolleriniGetir(
      userId: userId,
      firmaId: firmaId,
      client: client,
    );
    return birincilRolSec(roller, firmaRolu: firmaRolu);
  }

  static Future<bool> kullaniciHerhangiBirRoleSahipMi(
    Iterable<String> hedefRoller, {
    String? userId,
    String? firmaId,
    SupabaseClient? client,
  }) async {
    final roller = await kullaniciTumRolleriniGetir(
      userId: userId,
      firmaId: firmaId,
      client: client,
    );
    final hedefler = hedefRoller
        .map((rol) => RoleUtils.normalizeUserRole(rol))
        .whereType<String>()
        .toSet();
    return roller.any(hedefler.contains);
  }

  static Future<void> kullaniciOperasyonRolleriniKaydet({
    required String userId,
    required String firmaId,
    required Iterable<String> roller,
    required String firmaRolu,
    SupabaseClient? client,
  }) async {
    final db = client ?? _client;
    final temizRoller = roller
        .map((rol) => RoleUtils.normalizeUserRole(rol))
        .whereType<String>()
        .where((rol) => rol != 'admin')
        .toSet();

    final adminSatiriGerekli = isFirmaAdminRolu(firmaRolu);

    try {
      await db
          .from(DbTables.userRoles)
          .delete()
          .eq('user_id', userId)
          .eq('firma_id', firmaId)
          .neq('role', 'admin');
    } catch (_) {
      final mevcutRoller = await kullaniciOperasyonRolleriniGetir(
        userId: userId,
        firmaId: firmaId,
        client: db,
      );
      for (final rol in mevcutRoller.where((rol) => rol != 'admin')) {
        await db
            .from(DbTables.userRoles)
            .delete()
            .eq('user_id', userId)
            .eq('role', rol);
      }
    }

    if (temizRoller.isNotEmpty) {
      final satirlar = temizRoller
          .map((rol) => {
                'user_id': userId,
                'firma_id': firmaId,
                'role': rol,
                'aktif': true,
              })
          .toList();
      await db.from(DbTables.userRoles).insert(satirlar);
    }

    if (adminSatiriGerekli) {
      final adminData = {
        'user_id': userId,
        'firma_id': firmaId,
        'role': 'admin',
        'aktif': true,
      };
      try {
        await db.from(DbTables.userRoles).upsert(
              adminData,
              onConflict: 'user_id,firma_id,role',
            );
      } catch (_) {
        final mevcutAdmin = await db
            .from(DbTables.userRoles)
            .select('id')
            .eq('user_id', userId)
            .eq('role', 'admin')
            .maybeSingle();
        if (mevcutAdmin == null) {
          await db.from(DbTables.userRoles).insert(adminData);
        } else {
          await db.from(DbTables.userRoles).update(
              {'aktif': true, 'firma_id': firmaId}).eq('id', mevcutAdmin['id']);
        }
      }
    } else {
      try {
        await db
            .from(DbTables.userRoles)
            .delete()
            .eq('user_id', userId)
            .eq('firma_id', firmaId)
            .eq('role', 'admin');
      } catch (_) {}
    }
  }
}
