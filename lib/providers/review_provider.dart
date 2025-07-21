import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

final reviewsProvider =
    FutureProvider.family<List<Review>, int>((ref, activityId) {
  return reviewService.fetchReviews(activityId);
});

class ReviewSubmitData {
  const ReviewSubmitData({required this.activityId, required this.rating, required this.comment});
  final int activityId;
  final int rating;
  final String comment;
}

final submitReviewProvider =
    FutureProvider.family<Review, ReviewSubmitData>((ref, data) async {
  final review = await reviewService.createReview(
    data.activityId,
    data.rating,
    data.comment,
  );
  ref.invalidate(reviewsProvider(data.activityId));
  return review;
});
