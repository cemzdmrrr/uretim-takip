import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Giriş tercihlerini saklayan yardımcı sınıf.
///
/// Güvenlik nedeniyle parola tutulmaz. "Beni hatırla" davranışı,
/// Supabase'in kalıcı oturumu ile birlikte sadece e-posta ve tercih
/// bilgisini saklayacak şekilde uygulanır.
class SecureCredentialStorage {
  SecureCredentialStorage._();

  static const _emailKey = 'secure_email';
  static const _passwordKey = 'secure_password';
  static const _rememberMeKey = 'rememberMe';
  static const _legacyEmailKey = 'email';
  static const _legacyPasswordKey = 'password';

  /// Eski sürümlerde düz metin / base64 tutulan kayıtları temizler.
  ///
  /// - Parola hiçbir koşulda korunmaz.
  /// - "Beni hatırla" açıksa eski email güvenli anahtara taşınır.
  static Future<void> migrateLegacyStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final secureEmail = prefs.getString(_emailKey);
    final legacyEmail = prefs.getString(_legacyEmailKey);

    if (rememberMe &&
        secureEmail == null &&
        legacyEmail != null &&
        legacyEmail.isNotEmpty) {
      await prefs.setString(_emailKey, base64Encode(utf8.encode(legacyEmail)));
    }

    await prefs.remove(_passwordKey);
    await prefs.remove(_legacyPasswordKey);
    await prefs.remove(_legacyEmailKey);
  }

  /// Beni hatırla aktif mi
  static Future<bool> get isRememberMeEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
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

  /// Giriş tercihlerini kaydet
  static Future<void> save({
    required String email,
    bool rememberMe = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    await prefs.setString(_emailKey, base64Encode(utf8.encode(email)));

    // Eski parola kayıtlarını temizle (migration)
    await prefs.remove(_passwordKey);
    await prefs.remove(_legacyEmailKey);
    await prefs.remove(_legacyPasswordKey);
  }

  /// Tüm giriş tercihlerini sil
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);

    // Eski düz metin kayıtları da temizle
    await prefs.remove(_legacyEmailKey);
    await prefs.remove(_legacyPasswordKey);
  }
}
