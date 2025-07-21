import 'package:dio/dio.dart';
import '../models/activity.dart';
import 'api_client.dart';

class ActivityService {
  Future<List<Activity>> fetchMine() async {
    final res = await apiClient.get('/activities/', queryParameters: {'mine': '1'});
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Activity.fromJson)
        .toList();
  }

  Future<List<Activity>> fetchNearby() async {
    final res = await apiClient.get('/activities/', queryParameters: {'nearby': '1'});
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Activity.fromJson)
        .toList();
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
    String image,
  ) async {
    await apiClient.post('/activities/', data: {
      'sport': sport,
      'discipline': discipline,
      if (variant != null) 'variant': variant,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
      'image': image,
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
    String image,
  ) async {
    await apiClient.patch('/activities/' + id.toString() + '/', data: {
      'sport': sport,
      'discipline': discipline,
      'variant': variant,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'base_price': basePrice,
      'image': image,
    });
  }
}

final activityService = ActivityService();
