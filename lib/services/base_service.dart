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
  PostgrestFilterBuilder firmaQuery(String table, {String columns = '*'}) {
    return client.from(table).select(columns).eq('firma_id', firmaId);
  }

  /// Firma ID'yi otomatik ekleyerek INSERT yapar.
  Future<Map<String, dynamic>> firmaInsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    data['firma_id'] = firmaId;
    final response = await client.from(table).insert(data).select().single();
    return response;
  }

  /// Firma filtreli UPDATE yapar.
  Future<void> firmaUpdate(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    await client
        .from(table)
        .update(data)
        .eq('id', id)
        .eq('firma_id', firmaId);
  }

  /// Firma filtreli DELETE yapar.
  Future<void> firmaDelete(String table, String id) async {
    await client.from(table).delete().eq('id', id).eq('firma_id', firmaId);
  }
}
