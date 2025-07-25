import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/models/activity.dart';
import 'package:sports_booking_app/models/slot.dart';
import 'package:sports_booking_app/models/sport.dart';
import 'package:sports_booking_app/providers.dart';
import 'package:sports_booking_app/screens/activity_booking_page.dart';
import 'package:sports_booking_app/screens/payment_page.dart';

void main() {
  testWidgets('select slot and navigate to payment', (tester) async {
    final sport = Sport(id: 1, name: 'Tennis', banner: '', description: '');
    final slot = Slot(
      id: 1,
      sport: sport,
      title: 'Morning',
      location: 'Court',
      beginsAt: DateTime.now().add(const Duration(days: 1)),
      endsAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
      capacity: 10,
      price: 20,
      rating: 4.5,
      seatsLeft: 5,
    );
    final activity = Activity(
      id: 1,
      sport: 1,
      discipline: 1,
      variant: null,
      image: '',
      imageUrl: null,
      title: 'Tennis',
      description: '',
      difficulty: 1,
      duration: 60,
      basePrice: 10,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activitySlotsProvider.overrideWith((ref, _) async => [slot]),
          slotsByDateProvider.overrideWith(
              (ref, params) async => [slot]),
        ],
        child: MaterialApp(
          home: ActivityBookingPage(activity: activity),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Morning'));
    await tester.pump();
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentPage), findsOneWidget);
  });
}
