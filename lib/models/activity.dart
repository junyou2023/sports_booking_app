class Activity {
  Activity({
    required this.id,
    required this.sport,
    required this.discipline,
    required this.variant,
    required this.image,
    this.imageUrl,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.basePrice,
  });

  final int id;
  final int sport;
  final int discipline;
  final int? variant;
  final String image;
  final String? imageUrl;
  final String title;
  final String description;
  final int difficulty;
  final int duration;
  final double basePrice;

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
        id: j['id'] as int,
        sport: j['sport'] as int,
        discipline: j['discipline'] as int,
        variant: j['variant'] as int?,
        image: j['image'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        difficulty: j['difficulty'] as int? ?? 1,
        duration: j['duration'] as int? ?? 60,
        basePrice: (j['base_price'] as num).toDouble(),
      );
}
