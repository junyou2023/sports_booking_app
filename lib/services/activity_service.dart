import 'package:dio/dio.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import 'api_client.dart';

class ActivityService {
  int? _cachedOrgId; // R1

  Future<int?> _defaultOrg() async { // R1
    if (_cachedOrgId != null) return _cachedOrgId;
    final res = await apiClient.get('/merchant/orgs/me/');
    final data = res.data as List;
    if (data.isEmpty) {
      throw Exception('No organizations');
    }
    if (data.length == 1) {
      _cachedOrgId = data.first['id'] as int;
      return _cachedOrgId;
    }
    return null;
  }
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

  Future<Paginated<Activity>> fetchMine({String? q, int? category, int page = 1}) async { // R2
    return fetchActivities(params: { // R2
      'mine': '1', // R2
      if (q != null && q.isNotEmpty) 'q': q, // R2
      if (category != null) 'category': category, // R2
      'page': page, // R2
    }); // R2
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

  Future<void> deleteActivity(int id) async { // R2
    await apiClient.delete('/activities/' + id.toString() + '/'); // R2
  }

  Future<void> createActivity(
    int sport,
    int discipline,
    int? variant,
    String title,
    String description,
    int difficulty,
    int duration,
    double basePrice, {
    String? imagePath, // R1
    int? organizationId, // R1
  }) async {
    final org = organizationId ?? await _defaultOrg(); // R1
    final form = FormData.fromMap({ // R1
      'sport': sport,
      'discipline': discipline,
      if (variant != null) 'variant': variant,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
      if (org != null) 'organization': org,
    });
    if (imagePath != null) {
      form.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(imagePath, filename: imagePath.split('/').last),
      ));
    }
    await apiClient.post('/activities/', data: form); // R1
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
    double basePrice, {
    String? imagePath, // R1
    int? organizationId, // R1
  }) async {
    final org = organizationId ?? await _defaultOrg(); // R1
    final form = FormData.fromMap({ // R1
      'sport': sport,
      'discipline': discipline,
      'variant': variant,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
      if (org != null) 'organization': org,
    });
    if (imagePath != null) {
      form.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(imagePath, filename: imagePath.split('/').last),
      ));
    }
    await apiClient.patch('/activities/$id/', data: form); // R1
  }
}

final activityService = ActivityService();
