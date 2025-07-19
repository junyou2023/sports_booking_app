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
}

final activityService = ActivityService();
