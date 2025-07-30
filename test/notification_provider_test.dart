import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/providers/notification_provider.dart';
import 'package:sports_booking_app/services/notification_service.dart';
import 'package:sports_booking_app/models/app_notification.dart';
import 'package:sports_booking_app/services/notification_service.dart' show Paged;

class _FakeService extends NotificationService {
  int count;
  List<Paged<AppNotification>> pages;
  int calls = 0;
  _FakeService(this.count, this.pages);

  @override
  Future<int> unreadCount() async => count;

  @override
  Future<Paged<AppNotification>> listPaginated({int page = 1, bool unreadOnly = false}) async {
    calls++;
    return pages[page - 1];
  }
}

void main() {
  test('unreadCountProvider loads count', () async {
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(_FakeService(3, [])),
    ]);
    addTearDown(container.dispose);
    await container.read(unreadCountProvider.notifier).refresh();
    expect(container.read(unreadCountProvider), 3);
  });

  test('loadFirst sets hasNext from service', () async {
    final service = _FakeService(0, [
      Paged([
        AppNotification(
          id: 1,
          ntype: 'system',
          title: 'hi',
          body: 'there',
          data: const {},
          createdAt: DateTime.now(),
          readAt: null,
        )
      ], false)
    ]);
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    await container.read(notificationListProvider.notifier).loadFirst();
    final state = container.read(notificationListProvider);
    expect(state.items.length, 1);
    expect(state.hasNext, false);
  });

  test('loadMore avoids duplicate requests', () async {
    final service = _FakeService(0, [
      Paged([AppNotification(id: 1, ntype: 's', title: 'a', body: '', data: const {}, createdAt: DateTime.now(), readAt: null)], true),
      Paged([AppNotification(id: 2, ntype: 's', title: 'b', body: '', data: const {}, createdAt: DateTime.now(), readAt: null)], false),
    ]);
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(notificationListProvider.notifier);
    await notifier.loadFirst();
    await notifier.loadMore();
    await notifier.loadMore();
    final state = container.read(notificationListProvider);
    expect(state.page, 2);
    expect(service.calls, 2);
  });
}

