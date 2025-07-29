import 'package:dio/dio.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import 'api_client.dart';

class UnauthorizedError implements Exception {}

class FriendlyError implements Exception {
  FriendlyError(this.message);
  final String message;
  @override
  String toString() => message;
}

class FavoriteService {
  Future<Set<int>> fetchFavoriteIds() async {
    final Response res = await apiClient.get('/favorites/ids/');
    return (res.data as List).cast<int>().toSet();
  }

  Future<Paginated<Activity>> listFavorites({int page = 1, int pageSize = 20}) async {
    final Response res = await apiClient.get('/favorites/', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return Paginated.fromJson(res.data as Map<String, dynamic>,
        (j) => Activity.fromSimple(j['activity'] as Map<String, dynamic>));
  }

  Future<bool> toggle(int activityId) async {
    try {
      final Response res = await apiClient.post('/activities/$activityId/favorite/toggle/');
      return res.data['favorited'] as bool? ?? true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedError();
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        throw FriendlyError(e.response?.data['detail'].toString());
      }
      throw FriendlyError('Network error');
    }
  }
}

final favoriteService = FavoriteService();
