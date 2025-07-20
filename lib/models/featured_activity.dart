class FeaturedActivity {
  FeaturedActivity({required this.id, required this.activity, required this.image, required this.order});

  final int id;
  final int activity;
  final String image;
  final int order;

  factory FeaturedActivity.fromJson(Map<String, dynamic> j) => FeaturedActivity(
        id: j['id'] as int,
        activity: j['activity'] as int,
        image: j['image'] as String? ?? '',
        order: j['order'] as int? ?? 0,
      );
}
