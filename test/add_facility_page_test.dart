import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sports_booking_app/models/category.dart';
import 'package:sports_booking_app/screens/add_facility_page.dart';
import 'package:sports_booking_app/services/facility_service.dart';
import 'package:sports_booking_app/services/sports_service.dart';
import 'package:geocoding/geocoding.dart';

class _FakeFacilityService extends FacilityService {
  List<int>? seen;
  @override
  Future<void> createFacility(
      String name, double lat, double lng, List<int> categories,
      {double radius = 1000}) async {
    seen = categories;
  }
}

class _FakeSportsService extends SportsService {
  @override
  Future<List<Category>> fetchCategories() async {
    return [Category(id: 1, name: 'A')];
  }
}

void main() {
  testWidgets('address geocoding updates lat/lng and sends int categories',
      (tester) async {
    final service = _FakeFacilityService();
    await tester.pumpWidget(MaterialApp(
        home: AddFacilityPage(
      service: service,
      sportsService: _FakeSportsService(),
      geocode: (_) async => [Location(latitude: 1, longitude: 2)],
    )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byLabelText('Name'), 'F1');
    await tester.enterText(find.byLabelText('Address (optional)'), 'addr');
    await tester.tap(find.text('Use address'));
    await tester.pump();
    expect(find.textContaining('Location set to 1.00000, 2.00000'),
        findsOneWidget);
    await tester.tap(find.text('A'));
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(service.seen, [1]);
  });
}
