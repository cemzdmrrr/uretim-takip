import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_helper_rls_free.dart' as auth;

Future<String?> getCurrentUserRole() => auth.kullaniciRolunuGetir();

Future<String?> getCurrentUserId() async {
  return Supabase.instance.client.auth.currentUser?.id;
}
