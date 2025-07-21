import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';

final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  return activityService.fetchMine();
});

final nearbyActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  return activityService.fetchNearby();
});
