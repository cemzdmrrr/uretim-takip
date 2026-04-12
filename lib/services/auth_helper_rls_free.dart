import 'package:flutter/foundation.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// RLS devre dışı - basit admin kontrolü
Future<bool> kullaniciAdminMi() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final response = await Supabase.instance.client
        .from(DbTables.userRoles)
        .select()
        .eq('user_id', user.id)
        .eq('aktif', true)
        .maybeSingle();

    // Admin tüm yetkilere sahip
    return response != null && response['role'] == 'admin';
  } catch (e) {
    debugPrint('Admin kontrolü hatası: $e');
    return false;
  }
}

// Kullanıcının rolünü getir
Future<String?> kullaniciRolunuGetir() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response = await Supabase.instance.client
        .from(DbTables.userRoles)
        .select()
        .eq('user_id', user.id)
        .eq('aktif', true)
        .maybeSingle();

    return response?['role'];
  } catch (e) {
    debugPrint('Rol getirme hatası: $e');
    return null;
  }
}

// Admin veya belirli bir role sahip mi kontrolü
Future<bool> kullaniciYetkiKontrolu(List<String> yetkiliRoller) async {
  try {
    final userRole = await kullaniciRolunuGetir();
    if (userRole == null) return false;
    
    // Admin tüm yetkilere sahip
    if (userRole == 'admin') return true;
    
    // Belirli roller kontrol edilir
    return yetkiliRoller.contains(userRole);
  } catch (e) {
    debugPrint('Yetki kontrolü hatası: $e');
    return false;
  }
}

// Admin mi veya belirli bir rol için yetkili mi kontrolü
Future<bool> adminVeyaYetkiliMi(String? requiredRole) async {
  try {
    final userRole = await kullaniciRolunuGetir();
    if (userRole == null) return false;
    
    // Admin her şeyi yapabilir
    if (userRole == 'admin') return true;
    
    // Belirli rol kontrolü
    if (requiredRole != null) {
      return userRole == requiredRole;
    }
    
    return false;
  } catch (e) {
    debugPrint('Admin/yetki kontrolü hatası: $e');
    return false;
  }
}

// Kendini admin yapma fonksiyonu (test amaçlı)
Future<bool> kendimiAdminYap() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    await Supabase.instance.client
        .from(DbTables.userRoles)
        .upsert({
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

// Supabase admin fonksiyonunu çağır
Future<bool> supabaseAdminKontrolu() async {
  try {
    final response = await Supabase.instance.client
        .rpc('check_admin');
    
    return response == true;
  } catch (e) {
    debugPrint('Supabase admin kontrolü hatası: $e');
    return false;
  }
}
