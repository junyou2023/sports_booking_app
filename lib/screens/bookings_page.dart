import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/booking.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../widgets/booking_card.dart';
import 'activity_detail_page.dart';

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (List<Booking> bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (_, i) {
              final b = bookings[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BookingCard(
                  booking: b,
                  onTap: () async {
                    final Activity activity =
                        await activityService.fetchById(b.slot.activityId);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailPage(activity: activity),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
