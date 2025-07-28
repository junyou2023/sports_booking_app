import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_page.dart';
import '../services/activity_service.dart';

class ActivityQuery {
  const ActivityQuery({required this.categoryId, this.ordering, this.page = 1});
  final int categoryId;
  final String? ordering;
  final int page;
}

final activitiesByCategoryProvider =
    FutureProvider.family<ActivityPage, ActivityQuery>((ref, query) async {
  return activityService.fetchByCategory(
    query.categoryId,
    ordering: query.ordering,
    page: query.page,
  );
});
