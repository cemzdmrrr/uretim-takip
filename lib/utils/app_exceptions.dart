import 'package:flutter/foundation.dart';

/// Uygulama genelinde kullanılan hata sınıfı hiyerarşisi.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

/// Ağ/Supabase iletişim hataları
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// Kimlik doğrulama hataları
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Veri doğrulama hataları
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

/// İş mantığı hataları
class BusinessException extends AppException {
  const BusinessException(super.message, {super.code, super.originalError});
}

/// Merkezi loglama servisi.
///
/// Tüm hataları tek noktadan loglar. İleride Sentry/Firebase Crashlytics
/// entegrasyonu bu sınıf üzerinden yapılır.
class AppLogger {
  AppLogger._();

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ $message');
    if (error != null) debugPrint('   Detay: $error');
    if (stackTrace != null && kDebugMode) {
      debugPrint('   Stack: $stackTrace');
    }
    // TODO: Sentry/Crashlytics entegrasyonu
  }

  static void warning(String message, [Object? error]) {
    debugPrint('⚠️ $message');
    if (error != null) debugPrint('   Detay: $error');
  }

  static void info(String message) {
    debugPrint('ℹ️ $message');
  }

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔍 $message');
    }
  }
}
