class Category {
  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String icon;
  final String? imageUrl;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        icon: j['icon'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
      );
}
