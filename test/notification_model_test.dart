import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    final sampleMap = {
      'id': 'notif-1',
      'user_id': 'user-abc',
      'title': 'Yeni Sipariş',
      'message': 'Model XYZ için sipariş oluşturuldu',
      'created_at': '2025-06-15T14:30:00.000',
      'is_read': false,
    };

    test('fromMap creates instance with all fields', () {
      final model = NotificationModel.fromMap(sampleMap);
      expect(model.id, 'notif-1');
      expect(model.userId, 'user-abc');
      expect(model.title, 'Yeni Sipariş');
      expect(model.message, 'Model XYZ için sipariş oluşturuldu');
      expect(model.createdAt, DateTime(2025, 6, 15, 14, 30));
      expect(model.isRead, false);
    });

    test('fromJson delegates to fromMap', () {
      final model = NotificationModel.fromJson(sampleMap);
      expect(model.title, 'Yeni Sipariş');
    });

    test('fromMap defaults missing values', () {
      final minimal = <String, dynamic>{};
      final model = NotificationModel.fromMap(minimal);
      expect(model.id, '');
      expect(model.userId, '');
      expect(model.title, '');
      expect(model.message, '');
      expect(model.isRead, false);
    });

    test('toMap produces correct keys', () {
      final model = NotificationModel.fromMap(sampleMap);
      final map = model.toMap();
      expect(map['id'], 'notif-1');
      expect(map['user_id'], 'user-abc');
      expect(map['title'], 'Yeni Sipariş');
      expect(map['is_read'], false);
      expect(map['created_at'], contains('2025-06-15'));
    });

    test('toJson delegates to toMap', () {
      final model = NotificationModel.fromMap(sampleMap);
      expect(model.toJson(), model.toMap());
    });

    test('round-trip fromMap/toMap preserves data', () {
      final model = NotificationModel.fromMap(sampleMap);
      final map = model.toMap();
      final restored = NotificationModel.fromMap(map);
      expect(restored.id, model.id);
      expect(restored.userId, model.userId);
      expect(restored.title, model.title);
      expect(restored.isRead, model.isRead);
    });
  });
}
