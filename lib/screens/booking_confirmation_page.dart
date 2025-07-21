import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking #${booking.id}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Slot: ${booking.slot.title}'),
            Text('Date: ${booking.slot.beginsAt.toLocal()}'),
          ],
        ),
      ),
    );
  }
}
