class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'ATTENDANCE', 'TASK', 'LEAVE', 'SALARY', 'EXPENSE', 'SYSTEM'
  final bool isRead;
  final String? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      isRead: json['isRead'] ?? false,
      data: json['data'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
