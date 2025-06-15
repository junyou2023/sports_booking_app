// lib/models/sport.dart
//
// Model class that represents one sport / activity coming from the API.
// It also normalises the `banner` field so that the UI layer can load
// both remote URLs and local asset images transparently.

class Sport {
  Sport({
    required this.id,
    required this.name,
    required this.banner,        // already a full path – can be http or assets/
    required this.description,
  });

  final int id;
  final String name;
  final String banner;
  final String description;

  /// Factory that converts raw JSON into a [Sport] instance.
  /// If the `banner` string does NOT start with “http”, we treat it as an
  /// asset file name and prepend the local folder path.
  factory Sport.fromJson(Map<String, dynamic> json) {
    final raw = (json['banner'] as String?)?.trim() ?? '';
    final normalized = raw.startsWith('http')
        ? raw                               // remote URL – keep untouched
        : 'assets/images/$raw';             // local asset

    return Sport(
      id: json['id'] as int,
      name: json['name'] as String,
      banner: normalized,
      description: json['description'] ?? '',
    );
  }
}
