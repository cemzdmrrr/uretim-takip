import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Edge Function çağrılarını merkezi olarak yöneten servis.
/// Tüm SaaS edge function'ları bu servis üzerinden çağrılır.
class EdgeFunctionService {
  EdgeFunctionService._();
  static final EdgeFunctionService instance = EdgeFunctionService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Yeni firma oluşturur (onboarding akışında kullanılır)
  Future<Map<String, dynamic>> firmaOlustur({
    required String firmaAdi,
    required String firmaKodu,
    required String sepiaSektoru,
    required List<String> uretimDallari,
    required List<String> moduller,
  }) async {
    final response = await _client.functions.invoke(
      'firma-olustur',
      body: {
        'firma_adi': firmaAdi,
        'firma_kodu': firmaKodu,
        'sepiaSektoru': sepiaSektoru,
        'uretim_dallari': uretimDallari,
        'moduller': moduller,
      },
    );
    return _handleResponse(response);
  }

  /// Firmaya kullanıcı davet eder
  Future<Map<String, dynamic>> kullaniciDavetEt({
    required String firmaId,
    required String email,
    required String rol,
  }) async {
    final response = await _client.functions.invoke(
      'kullanici-davet',
      body: {
        'firma_id': firmaId,
        'email': email,
        'rol': rol,
      },
    );
    return _handleResponse(response);
  }

  /// Modül aktifleştirir veya deaktif eder
  Future<Map<String, dynamic>> modulAktivasyonDegistir({
    required String firmaId,
    required String modulKodu,
    required bool aktif,
  }) async {
    final response = await _client.functions.invoke(
      'modul-aktivasyon',
      body: {
        'firma_id': firmaId,
        'modul_kodu': modulKodu,
        'islem': aktif ? 'aktif' : 'pasif',
      },
    );
    return _handleResponse(response);
  }

  /// Platform raporu alır (admin paneli)
  Future<Map<String, dynamic>> platformRaporAl({
    String tip = 'genel',
    String? firmaId,
    int? gun,
  }) async {
    final params = <String, String>{'tip': tip};
    if (firmaId != null) params['firma_id'] = firmaId;
    if (gun != null) params['gun'] = gun.toString();

    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');

    final response = await _client.functions.invoke(
      'platform-rapor?$queryString',
      method: HttpMethod.get,
    );
    return _handleResponse(response);
  }

  /// Edge function yanıtını işler
  Map<String, dynamic> _handleResponse(FunctionResponse response) {
    if (response.status >= 400) {
      final body = response.data;
      final errorMsg = body is Map ? body['error'] ?? 'Bilinmeyen hata' : 'HTTP ${response.status}';
      throw EdgeFunctionException(errorMsg.toString(), response.status);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return {'data': data};
  }
}

/// Edge function hatalarını temsil eder
class EdgeFunctionException implements Exception {
  final String message;
  final int statusCode;

  EdgeFunctionException(this.message, this.statusCode);

  @override
  String toString() => 'EdgeFunctionException($statusCode): $message';
}
