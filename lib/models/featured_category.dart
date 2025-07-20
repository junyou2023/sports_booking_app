class FeaturedCategory {
  FeaturedCategory({required this.id, required this.category, required this.image, required this.order});

  final int id;
  final int category;
  final String image;
  final int order;

  factory FeaturedCategory.fromJson(Map<String, dynamic> j) => FeaturedCategory(
        id: j['id'] as int,
        category: j['category'] as int,
        image: j['image'] as String? ?? '',
        order: j['order'] as int? ?? 0,
      );
}
