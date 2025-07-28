import '../models/featured_category.dart';
import '../models/featured_activity.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import 'api_client.dart';

class HomeService {
  Future<List<FeaturedCategory>> fetchFeaturedCategories() async {
    final res = await apiClient.get('/featured-categories/');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(FeaturedCategory.fromJson)
        .toList(growable: false);
  }

  Future<List<FeaturedActivity>> fetchFeaturedActivities() async {
    final res = await apiClient.get('/featured-activities/');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(FeaturedActivity.fromJson)
        .toList(growable: false);
  }

  Paginated<Activity> _parse(Object data) {
    if (data is List) {
      return Paginated.fromList(
        data.cast<Map<String, dynamic>>(),
        Activity.fromJson,
      );
    }
    if (data is Map<String, dynamic>) {
      return Paginated.fromJson(data, Activity.fromJson);
    }
    return Paginated(count: 0, next: null, previous: null, results: const []);
  }

  Future<Paginated<Activity>> fetchContinuePlanning() async {
    final res = await apiClient.get('/home/continue-planning/');
    final data = res.data;
    if (data is List) {
      return Paginated.fromList(
        data.cast<Map<String, dynamic>>(),
        Activity.fromSimple,
      );
    }
    if (data is Map<String, dynamic>) {
      return Paginated.fromJson(data, Activity.fromSimple);
    }
    return Paginated(count: 0, next: null, previous: null, results: const []);
  }
}

final homeService = HomeService();
