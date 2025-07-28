import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import '../services/activity_service.dart';

final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  return activityService.fetchMine();
});

final nearbyActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  return activityService.fetchNearby();
});

final activitiesByCategoryProvider =
    FutureProvider.family<Paginated<Activity>, int>((ref, categoryId) async {
  return activityService.fetchActivitiesByCategory(categoryId);
});
