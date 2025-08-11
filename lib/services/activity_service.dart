import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

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
    final res = await apiClient.get('/activities/', queryParameters: params);
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
    final Response res = await apiClient.get('/activities/$id/');
    return Activity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Activity> createActivity(
    int sport,
    int discipline,
    int? variant,
    String title,
    String description,
    int difficulty,
    int duration,
    double basePrice, {
    int? organizationId,
    XFile? imageFile,
  }) async {
    final form = FormData.fromMap({
      'sport': sport,
      'discipline': discipline,
      if (variant != null) 'variant': variant,
      if (organizationId != null) 'organization': organizationId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
      if (imageFile != null)
        'image': await MultipartFile.fromFile(imageFile.path,
            filename: p.basename(imageFile.path)),
    });
    try {
      final res = await apiClient.post('/activities/', data: form);
      return Activity.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowFieldErrors(e);
      rethrow;
    }
  }

  Future<Activity> updateActivity(
    int id,
    int sport,
    int discipline,
    int? variant,
    String title,
    String description,
    int difficulty,
    int duration,
    double basePrice, {
    int? organizationId,
    XFile? imageFile,
  }) async {
    final form = FormData.fromMap({
      'sport': sport,
      'discipline': discipline,
      if (variant != null) 'variant': variant,
      if (organizationId != null) 'organization': organizationId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
      if (imageFile != null)
        'image': await MultipartFile.fromFile(imageFile.path,
            filename: p.basename(imageFile.path)),
    });
    try {
      final res = await apiClient.patch('/activities/$id/', data: form);
      return Activity.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowFieldErrors(e);
      rethrow;
    }
  }

  Future<void> deleteActivity(int id) async {
    await apiClient.delete('/activities/$id/');
  }

  Future<void> updateActivityStatus(int id, {required bool isActive}) async {
    await apiClient.patch('/activities/$id/', data: {'is_active': isActive});
  }

  void _rethrowFieldErrors(DioException e) {
    if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final map = <String, List<String>>{};
        data.forEach((key, value) {
          if (value is List) {
            map[key] = value.map((v) => v.toString()).toList();
          } else {
            map[key] = [value.toString()];
          }
        });
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: map,
        );
      }
    }
    throw e;
  }
}

final activityService = ActivityService();
