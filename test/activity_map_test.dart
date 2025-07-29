import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_booking_app/widgets/activity_map.dart';

void main() {
  testWidgets('shows placeholder when no coords', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ActivityMap(lat: null, lng: null, title: 'A')),
    ));
    expect(find.text('Location unavailable'), findsOneWidget);
  });

  testWidgets('renders map and buttons', (tester) async {
    // GoogleMap widget requires platform binding; use a fake binary messenger
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ActivityMap(lat: 0.0, lng: 0.0, title: 'Test'),
      ),
    ));
    expect(find.byType(ActivityMap), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNWidgets(2));
  });
}
