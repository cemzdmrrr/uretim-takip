import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/notification_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class NotificationService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _client.from(DbTables.notifications).insert({
      'firma_id': _firmaId,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': false,
    });
  }

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    final data = await _client
        .from(DbTables.notifications)
        .select('*')
        .eq('firma_id', _firmaId)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => NotificationModel.fromMap(e))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from(DbTables.notifications).update({'is_read': true}).eq('id', notificationId);
  }
}
