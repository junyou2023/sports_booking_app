import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_booking_app/models/slot.dart';
import 'package:sports_booking_app/models/sport.dart';
import 'package:sports_booking_app/providers.dart';

void main() {
  test('slotsByDateProvider caches fetches by params equality', () async {
    var callCount = 0;
    final sport = Sport(id: 1, name: 'S', banner: '', description: '');
    final fakeProvider = FutureProvider.family<List<Slot>, SlotsByDateParams>((ref, p) async {
      callCount++;
      return [
        Slot(
          id: 1,
          sport: sport,
          title: 't',
          location: 'l',
          beginsAt: DateTime(2025, 1, 1),
          endsAt: DateTime(2025, 1, 1, 1),
          capacity: 1,
          price: 1,
          rating: 5,
          seatsLeft: 1,
        ),
      ];
    });

    final container = ProviderContainer(overrides: [
      slotsByDateProvider.overrideWithProvider(fakeProvider),
    ]);
    addTearDown(container.dispose);

    final params = SlotsByDateParams(activityId: 1, date: DateTime(2025, 1, 1));
    await container.read(slotsByDateProvider(params).future);
    // same values but new instance
    await container.read(
      slotsByDateProvider(SlotsByDateParams(activityId: 1, date: DateTime(2025, 1, 1))).future,
    );
    expect(callCount, 1);
  });
}
