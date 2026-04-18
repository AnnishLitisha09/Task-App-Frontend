class NotificationModel {
  final int notificationId;
  final int userId;
  final String title;
  final String msg;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.msg,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: int.parse(json['notification_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      title: json['title'] ?? '',
      msg: json['msg'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'title': title,
      'msg': msg,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
