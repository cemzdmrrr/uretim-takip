import 'package:flutter/foundation.dart';

/// Ortam yapılandırması — derleme zamanında enjekte edilen APP_ENV değerine göre
/// farklı ortam ayarları sağlar.
///
/// .env dosyasına APP_ENV=production|staging|development ekleyin.
enum AppOrtam { development, staging, production }

class EnvironmentConfig {
  EnvironmentConfig._();

  static const String _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const String appUrl = String.fromEnvironment('APP_URL', defaultValue: 'http://localhost:3000');

  static AppOrtam get ortam {
    switch (_appEnv) {
      case 'production':
        return AppOrtam.production;
      case 'staging':
        return AppOrtam.staging;
      default:
        return AppOrtam.development;
    }
  }

  static bool get isProduction => ortam == AppOrtam.production;
  static bool get isStaging => ortam == AppOrtam.staging;
  static bool get isDevelopment => ortam == AppOrtam.development;

  /// Debug log'ları sadece development ve staging'de aktif
  static bool get showDebugLogs => !isProduction;

  /// Admin client kullanımı sadece development'da izinli
  static bool get allowAdminClient => isDevelopment;

  /// Ortam etiketini döndürür (debug UI için)
  static String get ortamEtiketi {
    switch (ortam) {
      case AppOrtam.production:
        return '';
      case AppOrtam.staging:
        return '[STAGING]';
      case AppOrtam.development:
        return '[DEV]';
    }
  }

  static void logOrtamBilgisi() {
    if (kDebugMode) {
      debugPrint('╔══════════════════════════════════════');
      debugPrint('║ TexPilot Ortam: ${ortam.name}');
      debugPrint('║ APP_URL: $appUrl');
      debugPrint('╚══════════════════════════════════════');
    }
  }
}
