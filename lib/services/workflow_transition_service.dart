import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/workflow_state_machine.dart';

class WorkflowTransitionService {
  WorkflowTransitionService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<bool> applyTransition({
    required String tableName,
    required dynamic recordId,
    required String firmaId,
    required String? fromStatus,
    required String toStatus,
    Map<String, dynamic> extraFields = const {},
    String? idempotencyKey,
  }) async {
    WorkflowStateMachine.ensureTransition(
      fromStatus: fromStatus,
      toStatus: toStatus,
      context: tableName,
    );

    try {
      await _supabase.rpc(
        'apply_workflow_transition',
        params: {
          'p_table_name': tableName,
          'p_record_id': recordId,
          'p_firma_id': firmaId,
          'p_from_status': fromStatus,
          'p_to_status': toStatus,
          'p_idempotency_key': idempotencyKey,
        },
      );

      if (extraFields.isNotEmpty) {
        await _updateWithTenantGuard(
          tableName: tableName,
          recordId: recordId,
          firmaId: firmaId,
          values: extraFields,
        );
      }

      return true;
    } catch (_) {
      final fallback = <String, dynamic>{
        'durum': toStatus,
        'updated_at': DateTime.now().toIso8601String(),
        ...extraFields,
      };

      await _updateWithTenantGuard(
        tableName: tableName,
        recordId: recordId,
        firmaId: firmaId,
        values: fallback,
      );
      return false;
    }
  }

  Future<void> _updateWithTenantGuard({
    required String tableName,
    required dynamic recordId,
    required String firmaId,
    required Map<String, dynamic> values,
  }) async {
    final data = Map<String, dynamic>.from(values);
    if (data.isEmpty) return;

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await _supabase
            .from(tableName)
            .update(data)
            .eq('id', recordId)
            .eq('firma_id', firmaId);
        return;
      } catch (e) {
        final missingWithTenant = _missingColumnName(e);
        if (missingWithTenant != null && data.containsKey(missingWithTenant)) {
          data.remove(missingWithTenant);
          if (data.isEmpty) return;
          continue;
        }

        try {
          await _supabase.from(tableName).update(data).eq('id', recordId);
          return;
        } catch (inner) {
          final missingNoTenant = _missingColumnName(inner);
          if (missingNoTenant != null && data.containsKey(missingNoTenant)) {
            data.remove(missingNoTenant);
            if (data.isEmpty) return;
            continue;
          }
          rethrow;
        }
      }
    }
  }

  String? _missingColumnName(Object error) {
    if (error is! PostgrestException) return null;
    final message =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'.toLowerCase();

    final schemaCache = RegExp(
      r"could\s+not\s+find\s+the\s+'([a-z0-9_]+)'\s+column",
    ).firstMatch(message);
    if (schemaCache != null) return schemaCache.group(1);

    final withTable = RegExp(
      r'column\s+[a-z0-9_]+\.([a-z0-9_]+)\s+does\s+not\s+exist',
    ).firstMatch(message);
    if (withTable != null) return withTable.group(1);

    final plain = RegExp(
      r'column\s+"?([a-z0-9_]+)"?\s+does\s+not\s+exist',
    ).firstMatch(message);
    return plain?.group(1);
  }
}
