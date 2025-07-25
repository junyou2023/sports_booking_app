import '../models/featured_category.dart';
import '../models/featured_activity.dart';
import '../models/activity.dart';
import 'api_client.dart';
import 'package:dio/dio.dart';

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

  Future<List<Activity>> fetchContinuePlanning() async {
    try {
      final res = await apiClient.get('/home/continue-planning/');
      return (res.data as List)
          .cast<Map<String, dynamic>>()
          .map(Activity.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return <Activity>[];
      }
      rethrow;
    }
  }
}

final homeService = HomeService();
