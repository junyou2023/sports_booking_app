class AppNotification {
  AppNotification({
    required this.id,
    required this.ntype,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String ntype;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        ntype: j['ntype'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? {},
        createdAt: DateTime.parse(j['created_at'] as String),
        readAt: j['read_at'] != null ? DateTime.parse(j['read_at']) : null,
      );
}
