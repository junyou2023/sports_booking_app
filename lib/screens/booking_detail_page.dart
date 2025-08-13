import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/booking.dart';
import '../models/activity.dart';

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking, required this.activity});

  final Booking booking;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final slot = booking.slot;
    final image = activity.imageUrl ?? activity.image;
    final begins = slot.beginsAt.toLocal();
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.isNotEmpty
                  ? (image.startsWith('http')
                      ? Image.network(
                          image,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/default.jpg',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          image,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ))
                  : Image.asset(
                      slot.sport.banner,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              slot.location,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${begins.toString().split(' ')[0]} • ${begins.hour.toString().padLeft(2, '0')}:${begins.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pax: ${booking.pax}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Center(
              child: QrImageView(
                data: booking.id.toString(),
                size: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

