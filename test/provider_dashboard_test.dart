import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sports_booking_app/models/activity.dart';
import 'package:sports_booking_app/models/paginated.dart';
import 'package:sports_booking_app/screens/provider_dashboard_page.dart';
import 'package:sports_booking_app/services/activity_service.dart';
import 'package:sports_booking_app/services/api_client.dart';

class _FakeActivityService extends ActivityService {
  @override
  Future<Paginated<Activity>> fetchActivities({Map<String, dynamic>? params}) async {
    return Paginated(count: 0, next: null, previous: null, results: []);
  }
}

void main() {
  testWidgets('dashboard has Create Sport entry and shows snackbar after create',
      (tester) async {
    apiClient = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
        h.resolve(Response(requestOptions: o, data: {}));
      }));
    await tester.pumpWidget(MaterialApp(home: ProviderDashboardPage(activitySvc: _FakeActivityService())));
    await tester.pumpAndSettle();
    expect(find.text('Create Sport'), findsOneWidget);
    await tester.tap(find.text('Create Sport'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byLabelText('Name'), 'S1');
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.text('Sport created'), findsWidgets);
  });
}
