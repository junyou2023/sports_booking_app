class Category {
  Category({required this.id, required this.name, required this.icon});

  final int id;
  final String name;
  final String icon;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        icon: j['icon'] as String? ?? '',
      );
}
