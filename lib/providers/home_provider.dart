import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/featured_category.dart';
import '../models/featured_activity.dart';
import '../services/home_service.dart';

final featuredCategoriesProvider =
    FutureProvider<List<FeaturedCategory>>((ref) async {
  return homeService.fetchFeaturedCategories();
});

final featuredActivitiesProvider =
    FutureProvider<List<FeaturedActivity>>((ref) async {
  return homeService.fetchFeaturedActivities();
});
