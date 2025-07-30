import '../models/app_notification.dart';
import '../models/paginated.dart';
import 'api_client.dart';

class NotificationService {
  Future<int> unreadCount() async {
    final res = await apiClient.get('notifications/unread_count/');
    return res.data['count'] as int? ?? 0;
  }

  Future<Paginated<AppNotification>> list({int page = 1, bool unreadOnly = false}) async {
    final res = await apiClient.get('notifications/', queryParameters: {
      'page': page,
      if (unreadOnly) 'unread': '1',
    });
    return Paginated.fromJson(res.data as Map<String, dynamic>, AppNotification.fromJson);
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
