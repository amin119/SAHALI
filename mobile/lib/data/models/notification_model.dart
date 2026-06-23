class NotificationModel {
  final String id;
  final String? reportId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.reportId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] as String,
        reportId: j['report_id'] as String?,
        title: j['title'] as String,
        body: j['body'] as String,
        isRead: (j['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
