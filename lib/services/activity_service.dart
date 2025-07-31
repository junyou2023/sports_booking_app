import 'package:dio/dio.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import 'api_client.dart';

class ActivityService {
  Paginated<Activity> _parsePage(Object data) {
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

  Future<Paginated<Activity>> fetchActivities({Map<String, dynamic>? params}) async {
    final res = await apiClient.get('activities/', queryParameters: params);
    return _parsePage(res.data);
  }

  Future<Paginated<Activity>> fetchMine() async {
    return fetchActivities(params: {'mine': '1'});
  }

  Future<Paginated<Activity>> fetchNearby() async {
    return fetchActivities(params: {'nearby': '1'});
  }

  Future<Paginated<Activity>> fetchActivitiesByCategory(
    int categoryId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return fetchActivities(params: {
      'category': categoryId,
      'page': page,
      'page_size': pageSize,
    });
  }

  Future<Paginated<Activity>> searchActivities({
    required String query,
    int? categoryId,
    int page = 1,
  }) async {
    return fetchActivities(params: {
      'q': query,
      if (categoryId != null) 'category': categoryId,
      'page': page,
    });
  }

  Future<Activity> fetchById(int id) async {
    final Response res = await apiClient.get('activities/$id/');
    return Activity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> createActivity(
    int sport,
    int discipline,
    int? variant,
    String title,
    String description,
    int difficulty,
    int duration,
    double basePrice,
  ) async {
    await apiClient.post('activities/', data: {
      'sport': sport,
      'discipline': discipline,
      if (variant != null) 'variant': variant,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
    });
  }

  Future<void> updateActivity(
    int id,
    int sport,
    int discipline,
    int? variant,
    String title,
    String description,
    int difficulty,
    int duration,
    double basePrice,
  ) async {
    await apiClient.patch('activities/' + id.toString() + '/', data: {
      'sport': sport,
      'discipline': discipline,
      'variant': variant,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
    });
  }
}

final activityService = ActivityService();
