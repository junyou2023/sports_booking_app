import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/models/activity.dart';
import 'package:sports_booking_app/models/slot.dart';
import 'package:sports_booking_app/models/sport.dart';
import 'package:sports_booking_app/screens/activity_booking_page.dart';
import 'package:sports_booking_app/screens/payment_page.dart';
import 'package:sports_booking_app/widgets/slot_card.dart';
import 'package:sports_booking_app/providers.dart';

void main() {
  testWidgets('slot selection shows CTA and navigates', (tester) async {
    final sport = Sport(id: 1, name: 'Tennis', banner: 'assets/images/sailing.jpg', description: '');
    final slot = Slot(
      id: 1,
      sport: sport,
      title: 'Morning Game',
      location: 'Court 1',
      beginsAt: DateTime(2024, 1, 1),
      endsAt: DateTime(2024, 1, 1, 1),
      capacity: 10,
      price: 20,
      rating: 5,
      seatsLeft: 10,
    );
    final activity = Activity(
      id: 1,
      sport: 1,
      discipline: 1,
      variant: null,
      image: '',
      imageUrl: null,
      title: 'Tennis Game',
      description: '',
      difficulty: 1,
      duration: 60,
      basePrice: 20,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activitySlotsProvider.overrideWith((ref, id) async => [slot]),
          slotsByDateProvider.overrideWith((ref, params) async => [slot]),
        ],
        child: MaterialApp(home: ActivityBookingPage(activity: activity)),
      ),
    );

    await tester.pump();
    await tester.pump();
    expect(find.byType(SlotCard), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.byType(SlotCard));
    await tester.pump();
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.byType(PaymentPage), findsOneWidget);
  }, skip: true);
}
