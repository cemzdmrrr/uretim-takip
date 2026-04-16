import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Tüm firma bazlı servislerin kullanabileceği temel yardımcı sınıf.
///
/// Static servisler doğrudan [TenantManager.instance.requireFirmaId] kullanabilir.
/// Instance servisler bu sınıfı extend edebilir.
///
/// ```dart
/// class MyService extends BaseService {
///   Future<List<MyModel>> listele() async {
///     final response = await firmaQuery('my_table').order('created_at');
///     return response.map((json) => MyModel.fromJson(json)).toList();
///   }
/// }
/// ```
abstract class BaseService {
  final SupabaseClient client = Supabase.instance.client;

  String get firmaId => TenantManager.instance.requireFirmaId;

  /// Firma filtreli SELECT sorgusu oluşturur.
  ///
  /// Güvenlik katmanı veritabanındaki RLS'dir; bu filtre yalnızca
  /// UX, performans ve yanlış tenant verisini istemciye taşımamak için kullanılır.
  PostgrestFilterBuilder firmaQuery(String table, {String columns = '*'}) {
    return client.from(table).select(columns).eq('firma_id', firmaId);
  }

  /// Payload'a aktif firma bağlamını kopyalayarak ekler.
  Map<String, dynamic> firmaPayload(Map<String, dynamic> data) {
    final scopedData = Map<String, dynamic>.from(data);
    scopedData['firma_id'] = firmaId;
    return scopedData;
  }

  /// Firma ID'yi otomatik ekleyerek INSERT yapar.
  Future<Map<String, dynamic>> firmaInsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final payload = firmaPayload(data);
    final response = await client.from(table).insert(payload).select().single();
    return response;
  }

  /// Firma filtreli UPDATE yapar.
  Future<void> firmaUpdate(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data)..remove('firma_id');
    await client
        .from(table)
        .update(payload)
        .eq('id', id)
        .eq('firma_id', firmaId);
  }

  /// Firma filtreli DELETE yapar.
  Future<void> firmaDelete(String table, String id) async {
    await client.from(table).delete().eq('id', id).eq('firma_id', firmaId);
  }
}
