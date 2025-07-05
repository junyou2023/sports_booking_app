// lib/models/sport.dart
class Sport {
  Sport({
    required this.id,
    required this.name,
    required this.banner,
    required this.description,
  });

  final int    id;
  final String name;
  final String banner;          // 绝对 http(s) 或 asset 路径；永不为空
  final String description;

  factory Sport.fromJson(Map<String, dynamic> json) {
    final raw = (json['banner'] as String?)?.trim() ?? '';

    late final String normalized;
    if (raw.startsWith('http')) {
      // 完整网络 URL
      normalized = raw;
    } else if (raw.startsWith('assets/')) {
      // 已经是 asset 路径
      normalized = raw;
    } else if (raw.isNotEmpty) {
      // 文件名 → 拼 asset
      normalized = 'assets/images/$raw';
    } else {
      // 空值 → 占位图
      normalized = 'assets/images/default.jpg';
    }

    return Sport(
      id:          json['id'] as int,
      name:        json['name'] as String,
      banner:      normalized,
      description: json['description'] ?? '',
    );
  }
}
