class SportCategory {
  SportCategory({required this.id, required this.name, this.parent, required this.fullPath});

  final int id;
  final String name;
  final int? parent;
  final String fullPath;

  factory SportCategory.fromJson(Map<String, dynamic> j) => SportCategory(
        id: j['id'] as int,
        name: j['name'] as String,
        parent: j['parent'] as int?,
        fullPath: j['full_path'] as String? ?? '',
      );
}
