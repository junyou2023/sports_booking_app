import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/screens/home_page.dart';

void main() {
  testWidgets('Home screen adapts to different screen sizes', (tester) async {
    Future<void> pumpFor(Size size) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomePage())));
      await tester.pumpAndSettle();
    }

    // Android phone dimensions
    await pumpFor(const Size(1080, 1920));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    // iPad dimensions
    await pumpFor(const Size(2048, 2732));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
