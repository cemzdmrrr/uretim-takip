import 'package:flutter/foundation.dart';

/// Uygulama genelinde tutarlı loglama.
/// İleriki aşamada Sentry, Crashlytics gibi servislere bağlanabilir.
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    debugPrint('ℹ️ [$tag] $message');
  }

  static void warning(String tag, String message) {
    debugPrint('⚠️ [$tag] $message');
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ [$tag] $message');
    if (error != null) debugPrint('  Hata: $error');
    if (stackTrace != null) debugPrint('  Stack: $stackTrace');
  }
}
