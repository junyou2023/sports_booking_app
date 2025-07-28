class FeaturedCategory {
  FeaturedCategory({required this.id, required this.category, required this.image, required this.displayOrder, required this.showOnHome});

  final int id;
  final int category;
  final String image;
  final int displayOrder;
  final bool showOnHome;

  factory FeaturedCategory.fromJson(Map<String, dynamic> j) => FeaturedCategory(
        id: j['id'] as int,
        category: j['category'] as int,
        image: j['image'] as String? ?? '',
        displayOrder: j['display_order'] as int? ?? 0,
        showOnHome: j['show_on_home'] as bool? ?? true,
      );
}
