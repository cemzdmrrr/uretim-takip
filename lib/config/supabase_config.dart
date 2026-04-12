import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase yapılandırması — kimlik bilgileri derleme zamanında enjekte edilir.
///
/// Çalıştırma:
///   flutter run --dart-define-from-file=.env
///
/// .env dosyası .gitignore'dadır ve kaynak kodda hiçbir anahtar tutulmaz.
/// Örnek dosya için .env.example dosyasına bakın.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase proje URL'si (--dart-define ile enjekte edilir)
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon key (--dart-define ile enjekte edilir)
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Service role key — YALNIZCA geliştirme ortamında admin işlemler için.
  /// Prodüksiyon yapılarında bu anahtar DAHİL EDİLMEMELİDİR.
  /// Admin işlemleri ileride Supabase Edge Function'a taşınmalıdır.
  static const String _serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

  /// Yapılandırmanın geçerli olup olmadığını doğrular.
  /// main() içinde Supabase.initialize()'den ÖNCE çağrılmalıdır.
  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase yapılandırması eksik!\n'
        'Uygulamayı şu şekilde çalıştırın:\n'
        '  flutter run --dart-define-from-file=.env\n'
        '\n'
        '.env dosyası oluşturmak için .env.example dosyasını kopyalayın.',
      );
    }
  }

  /// Admin özelliklerinin kullanılabilir olup olmadığını döndürür.
  static bool get isAdminAvailable => _serviceRoleKey.isNotEmpty;

  /// Supabase.initialize() için (main.dart'ta kullanılır)
  static Future<void> initialize() async {
    validate();
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
    } catch (e) {
      if (!e.toString().contains('already initialized')) {
        rethrow;
      }
    }
  }

  /// Admin işlemler için ayrı SupabaseClient (kullanıcı oluşturma vb.)
  /// Yalnızca service role key sağlandığında kullanılabilir.
  static SupabaseClient get adminClient {
    if (!isAdminAvailable) {
      throw StateError(
        'Service role key yapılandırılmamış.\n'
        'Admin işlemleri için .env dosyasına SUPABASE_SERVICE_ROLE_KEY ekleyin.\n'
        'NOT: Prodüksiyon yapılarında bu anahtar istemcide olmamalıdır.',
      );
    }
    if (kDebugMode) {
      debugPrint('⚠️ Admin client kullanılıyor — prodüksiyon için Edge Function\'a taşıyın.');
    }
    return SupabaseClient(url, _serviceRoleKey);
  }

  /// Normal istemci (singleton)
  static SupabaseClient get client => Supabase.instance.client;
}
