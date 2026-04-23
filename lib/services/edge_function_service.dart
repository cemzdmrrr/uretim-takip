import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Edge function cagri yonetimi.
class EdgeFunctionService {
  EdgeFunctionService._();

  static final EdgeFunctionService instance = EdgeFunctionService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Yeni firma olusturur.
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

  /// Firmaya kullanici davet eder.
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

  /// Modul aktivasyonunu degistirir.
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

  /// Platform raporu alir.
  Future<Map<String, dynamic>> platformRaporAl({
    String tip = 'genel',
    String? firmaId,
    int? gun,
  }) async {
    final params = <String, String>{'tip': tip};
    if (firmaId != null) params['firma_id'] = firmaId;
    if (gun != null) params['gun'] = gun.toString();

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');

    final response = await _client.functions.invoke(
      'platform-rapor?$queryString',
      method: HttpMethod.get,
    );
    return _handleResponse(response);
  }

  /// Firmayi ve iliskili tenant verilerini siler.
  Future<Map<String, dynamic>> firmaSil({
    required String firmaId,
  }) async {
    final response = await _client.functions.invoke(
      'firma-sil',
      body: {
        'firma_id': firmaId,
      },
    );
    return _handleResponse(response);
  }

  /// Yeni auth kullanicisi olusturup personel kaydini ekler.
  Future<Map<String, dynamic>> personelOlustur(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(
      'personel-olustur',
      body: body,
    );
    return _handleResponse(response);
  }

  /// Personel durum veya silme islemlerini yonetir.
  Future<Map<String, dynamic>> personelYonet({
    required String action,
    required String firmaId,
    required String userId,
    required String tckn,
    String? neden,
    String? cikisTarihi,
  }) async {
    final response = await _client.functions.invoke(
      'personel-yonet',
      body: {
        'action': action,
        'firma_id': firmaId,
        'user_id': userId,
        'tckn': tckn,
        if (neden != null && neden.trim().isNotEmpty) 'neden': neden.trim(),
        if (cikisTarihi != null && cikisTarihi.trim().isNotEmpty)
          'cikis_tarihi': cikisTarihi.trim(),
      },
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(FunctionResponse response) {
    if (response.status >= 400) {
      final body = response.data;
      final errorMsg = body is Map
          ? body['error'] ?? 'Bilinmeyen hata'
          : 'HTTP ${response.status}';
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

class EdgeFunctionException implements Exception {
  final String message;
  final int statusCode;

  EdgeFunctionException(this.message, this.statusCode);

  @override
  String toString() => 'EdgeFunctionException($statusCode): $message';
}
