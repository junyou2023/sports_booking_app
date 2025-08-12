import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sports_booking_app/models/category.dart';
import 'package:sports_booking_app/screens/add_facility_page.dart';
import 'package:sports_booking_app/services/facility_service.dart';
import 'package:sports_booking_app/services/sports_service.dart';

class _FakeFacilityService extends FacilityService {
  List<int>? seen;
  @override
  Future<void> createFacility(
      String name, double? lat, double? lng, List<int> categories,
      {double radius = 1000}) async {
    seen = categories;
  }
}

class _FakeSportsService extends SportsService {
  @override
  Future<List<Category>> fetchCategories() async {
    return [Category(id: 1, name: 'A', icon: '')];
  }
}

void main() {
  testWidgets('manual coordinates send int categories', (tester) async {
    final service = _FakeFacilityService();
    await tester.pumpWidget(MaterialApp(
        home: AddFacilityPage(
      service: service,
      sportsSvc: _FakeSportsService(),
    )));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'F1');
    await tester.tap(find.text('Enter coordinates manually'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Latitude'), '1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Longitude'), '2');
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(service.seen, [1]);
  });
}
