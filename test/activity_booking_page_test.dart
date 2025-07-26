import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/models/activity.dart';
import 'package:sports_booking_app/models/slot.dart';
import 'package:sports_booking_app/models/sport.dart';
import 'package:sports_booking_app/providers.dart';
import 'package:sports_booking_app/screens/activity_booking_page.dart';
import 'package:sports_booking_app/widgets/slot_card.dart';

class TestObserver extends NavigatorObserver {
  int pushCount = 0;
  @override
  void didPush(Route route, Route? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  testWidgets('shows slots and navigates to payment', (tester) async {
    final sport = Sport(id: 1, name: 'S', banner: '', description: '');
    final slot = Slot(
      id: 1,
      sport: sport,
      title: 'Morning',
      location: 'Court',
      beginsAt: DateTime(2025, 1, 1, 10),
      endsAt: DateTime(2025, 1, 1, 11),
      capacity: 1,
      price: 1,
      rating: 5,
      seatsLeft: 1,
    );
    final activity = Activity(
      id: 1,
      sport: 1,
      discipline: 1,
      variant: null,
      image: '',
      imageUrl: null,
      title: 'A',
      description: '',
      difficulty: 1,
      duration: 60,
      basePrice: 1,
    );

    final overrides = [
      activitySlotsProvider.overrideWith((ref, id) async => [slot]),
      slotsByDateProvider.overrideWithProvider(
        FutureProvider.family((ref, SlotsByDateParams p) async => [slot]),
      ),
    ];
    final observer = TestObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: ActivityBookingPage(activity: activity),
          navigatorObservers: [observer],
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No upcoming slots'), findsNothing);
    expect(find.byType(ChoiceChip), findsWidgets);

    // select first chip
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();

    // slot card should appear
    expect(find.byType(SlotCard), findsOneWidget);

    // tap slot
    await tester.tap(find.byType(SlotCard));
    await tester.pumpAndSettle();

    // continue button enabled
    final btn = find.text('Continue');
    expect(tester.widget<ElevatedButton>(btn).onPressed, isNotNull);

    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(observer.pushCount, 1);
  });
}
