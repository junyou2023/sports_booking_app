import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/booking.dart';

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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final b = bookings[i];
              return ListTile(
                title: Text(b.slot.title),
                subtitle: Text(
                  '${b.slot.beginsAt.toLocal()}'.split(' ')[0],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
