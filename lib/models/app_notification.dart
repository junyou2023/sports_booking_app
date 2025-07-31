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

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final rawData = j['data'];
    Map<String, dynamic> safeData;
    if (rawData is Map) {
      safeData = Map<String, dynamic>.from(rawData as Map);
    } else {
      safeData = {};
    }
    DateTime? read;
    final ra = j['read_at'];
    if (ra is String && ra.isNotEmpty) {
      read = DateTime.parse(ra);
    }
    return AppNotification(
      id: j['id'] as int,
      ntype: j['ntype'] as String? ?? '',
      title: j['title'] as String? ?? '',
      body: j['body'] as String? ?? '',
      data: safeData,
      createdAt: DateTime.parse(j['created_at'] as String),
      readAt: read,
    );
  }
}
