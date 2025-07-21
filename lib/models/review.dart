class Review {
  Review({
    required this.id,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final String userEmail;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as int,
        userEmail: j['user_email'] as String? ?? '',
        rating: j['rating'] as int? ?? 0,
        comment: j['comment'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
