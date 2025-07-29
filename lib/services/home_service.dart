import 'package:dio/dio.dart';
import '../models/featured_category.dart';
import '../models/featured_activity.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import 'api_client.dart';
import '../utils/errors.dart';

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
    try {
      final res = await apiClient.get('/home/continue-planning/');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final acts = list
          .map(
            (j) => Activity(
              id: j['id'] as int,
              title: j['title'] as String,
              imageUrl: j['image_url'] as String?,
              basePrice: (j['base_price'] as num?)?.toDouble() ?? 0.0,
              sport: 0,
              discipline: 0,
              variant: null,
              image: '',
              description: '',
              difficulty: 1,
              duration: 60,
            ),
          )
          .toList(growable: false);
      return Paginated(
        count: acts.length,
        next: null,
        previous: null,
        results: acts,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const FriendlyError('请先登录后再查看 Continue planning',
            unauthorized: true);
      }
      throw const FriendlyError('加载 Continue planning 失败，请稍后重试');
    }
  }
}

final homeService = HomeService();
