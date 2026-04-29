import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/user_role_service.dart';

Future<bool> kullaniciAdminMi() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return await UserRoleService.kullaniciHerhangiBirRoleSahipMi(
      const ['admin', 'firma_admin', 'firma_sahibi'],
      userId: user.id,
    );
  } catch (e) {
    debugPrint('Admin kontrolü hatası: $e');
    return false;
  }
}

Future<String?> kullaniciRolunuGetir() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return await UserRoleService.kullaniciBirincilRolunuGetir(userId: user.id);
  } catch (e) {
    debugPrint('Rol getirme hatası: $e');
    return null;
  }
}

Future<Set<String>> kullaniciRolleriniGetir() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};
    return await UserRoleService.kullaniciTumRolleriniGetir(userId: user.id);
  } catch (e) {
    debugPrint('Roller getirme hatası: $e');
    return {};
  }
}

Future<bool> kullaniciYetkiKontrolu(List<String> yetkiliRoller) async {
  try {
    final roller = await kullaniciRolleriniGetir();
    if (roller.isEmpty) return false;
    if (roller.contains('admin') ||
        roller.contains('firma_admin') ||
        roller.contains('firma_sahibi')) {
      return true;
    }
    return yetkiliRoller.any(roller.contains);
  } catch (e) {
    debugPrint('Yetki kontrolü hatası: $e');
    return false;
  }
}

Future<bool> adminVeyaYetkiliMi(String? requiredRole) async {
  try {
    final roller = await kullaniciRolleriniGetir();
    if (roller.isEmpty) return false;
    if (roller.contains('admin') ||
        roller.contains('firma_admin') ||
        roller.contains('firma_sahibi')) {
      return true;
    }
    if (requiredRole == null) return false;
    return roller.contains(requiredRole);
  } catch (e) {
    debugPrint('Admin/yetki kontrolü hatası: $e');
    return false;
  }
}

Future<bool> kendimiAdminYap() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    await Supabase.instance.client.from(DbTables.userRoles).insert({
      'user_id': user.id,
      'role': 'admin',
      'aktif': true,
    });

    return true;
  } catch (e) {
    debugPrint('Admin yapma hatası: $e');
    return false;
  }
}

Future<bool> supabaseAdminKontrolu() async {
  try {
    final response = await Supabase.instance.client.rpc('check_admin');
    return response == true;
  } catch (e) {
    debugPrint('Supabase admin kontrolü hatası: $e');
    return false;
  }
}
