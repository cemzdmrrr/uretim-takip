import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Kimlik bilgilerini saklayan yardımcı sınıf.
///
/// SharedPreferences üzerinde base64 encoding ile saklar.
/// Windows masaüstünde flutter_secure_storage ATL bağımlılığı
/// sorun yarattığı için bu yaklaşım tercih edilmiştir.
class SecureCredentialStorage {
  SecureCredentialStorage._();

  static const _emailKey = 'secure_email';
  static const _passwordKey = 'secure_password';

  /// Beni hatırla aktif mi
  static Future<bool> get isRememberMeEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false;
  }

  /// Kayıtlı email
  static Future<String?> get savedEmail async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_emailKey);
    if (encoded == null) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return encoded; // eski düz metin migration
    }
  }

  /// Kayıtlı şifre
  static Future<String?> get savedPassword async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_passwordKey);
    if (encoded == null) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return encoded; // eski düz metin migration
    }
  }

  /// Kimlik bilgilerini kaydet
  static Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', true);
    await prefs.setString(_emailKey, base64Encode(utf8.encode(email)));
    await prefs.setString(_passwordKey, base64Encode(utf8.encode(password)));

    // Eski düz metin kayıtları temizle (migration)
    await prefs.remove('email');
    await prefs.remove('password');
  }

  /// Tüm kimlik bilgilerini sil
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);

    // Eski düz metin kayıtları da temizle
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
