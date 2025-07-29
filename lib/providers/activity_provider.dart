import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import '../services/activity_service.dart';

final activitiesProvider = FutureProvider<Paginated<Activity>>((ref) async {
  return activityService.fetchMine();
});

final nearbyActivitiesProvider = FutureProvider<Paginated<Activity>>((ref) async {
  return activityService.fetchNearby();
});

// autoDispose so that list refreshes when returning after adding new activity
final activitiesByCategoryProvider = FutureProvider.autoDispose
    .family<Paginated<Activity>, int>((ref, categoryId) async {
  return activityService.fetchActivitiesByCategory(categoryId);
});
