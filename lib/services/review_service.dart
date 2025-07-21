import 'package:dio/dio.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  Future<List<Review>> fetchReviews(int activityId, {int? limit}) async {
    final Response res = await apiClient.get(
      '/activities/$activityId/reviews/',
      queryParameters: limit != null ? {'limit': limit} : null,
    );
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList(growable: false);
  }

  Future<Review> createReview(
      int activityId, int rating, String comment) async {
    final Response res = await apiClient.post(
      '/activities/$activityId/reviews/',
      data: {'rating': rating, 'comment': comment},
    );
    return Review.fromJson(res.data as Map<String, dynamic>);
  }
}

final reviewService = ReviewService();
