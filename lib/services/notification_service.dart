import '../models/app_notification.dart';
import 'api_client.dart';

class Paged<T> {
  final List<T> items;
  final bool hasNext;
  const Paged(this.items, this.hasNext);
}

class NotificationService {
  Future<int> unreadCount() async {
    final res = await apiClient.get('notifications/unread_count/');
    return res.data['count'] as int? ?? 0;
  }

  Future<Paged<AppNotification>> listPaginated({int page = 1, bool unreadOnly = false}) async {
    final res = await apiClient.get('notifications/', queryParameters: {
      'page': page,
      if (unreadOnly) 'unread': '1',
    });
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final results = (data['results'] as List).cast<Map<String, dynamic>>();
      final items = results.map(AppNotification.fromJson).toList();
      final hasNext = data['next'] != null;
      return Paged(items, hasNext);
    } else if (data is List) {
      final items = data.cast<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
      final hasNext = items.length == 20;
      return Paged(items, hasNext);
    }
    return const Paged([], false);
  }

  Future<List<AppNotification>> list({int page = 1, bool unreadOnly = false}) async {
    final pg = await listPaginated(page: page, unreadOnly: unreadOnly);
    return pg.items;
  }

  Future<void> markAllRead() async {
    await apiClient.post('notifications/mark_all_read/');
  }

  Future<void> markRead(int id) async {
    await apiClient.post('notifications/$id/read/');
  }

  Future<void> registerDevice(String token, String platform) async {
    await apiClient.post('devices/', data: {'token': token, 'platform': platform});
  }
}

final notificationService = NotificationService();
