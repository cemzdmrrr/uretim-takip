/// Uygulama içi bildirim modeli.
///
/// Kullanıcıya gönderilen bildirimleri (başlık, mesaj, okunma durumu) temsil eder.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? firmaId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.firmaId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel.fromMap(json);

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] ?? false,
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'firma_id': firmaId,
    };
  }
}
