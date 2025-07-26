// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sports_booking_app/main.dart';

void main() {
  testWidgets('home page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SportsBookingApp()));
    await tester.pump();
    expect(find.textContaining('Discover'), findsOneWidget);
  });
}
