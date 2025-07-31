import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_booking_app/providers/notification_provider.dart';
import 'package:sports_booking_app/screens/notifications_page.dart';
import 'package:sports_booking_app/models/app_notification.dart';
import 'package:sports_booking_app/services/notification_service.dart';
import 'package:sports_booking_app/services/notification_service.dart' show Paged;

class _FakeService extends NotificationService {
  int calls = 0;
  @override
  Future<Paged<AppNotification>> listPaginated({int page = 1, bool unreadOnly = false}) async {
    calls++;
    return Paged([
      AppNotification(
        id: 1,
        ntype: 'system',
        title: 'Hello',
        body: 'World',
        data: const {},
        createdAt: DateTime.now(),
        readAt: null,
      )
    ], false);
  }

  @override
  Future<int> unreadCount() async => 1;
}

void main() {
  testWidgets('NotificationsPage displays list', (tester) async {
    final svc = _FakeService();
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(svc.calls, 1);
  });
}

