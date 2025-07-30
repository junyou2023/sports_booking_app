import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/providers/notification_provider.dart';
import 'package:sports_booking_app/services/notification_service.dart';

class _FakeService extends NotificationService {
  int count;
  _FakeService(this.count);
  @override
  Future<int> unreadCount() async => count;
}

void main() {
  test('unreadCountProvider loads count', () async {
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(_FakeService(3)),
    ]);
    addTearDown(container.dispose);
    await container.read(unreadCountProvider.notifier).refresh();
    expect(container.read(unreadCountProvider), 3);
  });
}

