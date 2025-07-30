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
  final String banner;          // Absolute http(s) or asset path; never empty
  final String description;

  factory Sport.fromJson(Map<String, dynamic> json) {
    final raw = (json['banner'] as String?)?.trim() ?? '';

    late final String normalized;
    if (raw.startsWith('http')) {
      // Full network URL
      normalized = raw;
    } else if (raw.startsWith('assets/')) {
      // Already an asset path
      normalized = raw;
    } else if (raw.isNotEmpty) {
      // File name → prepend asset path
      normalized = 'assets/images/$raw';
    } else {
      // Empty → placeholder image
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
