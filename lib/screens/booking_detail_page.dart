import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/activity.dart';
import '../models/booking.dart';

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking, required this.activity});

  final Booking booking;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final slot = booking.slot;
    final image = activity.imageUrl ?? activity.image;
    final begins = slot.beginsAt.toLocal();
    final dateStr =
        '${begins.toString().split(' ')[0]} • ${begins.hour.toString().padLeft(2, '0')}:${begins.minute.toString().padLeft(2, '0')}';
    final theme = Theme.of(context);
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
              style: theme.textTheme.headlineSmall,
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                activity.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.place_outlined,
                      text: slot.location,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.schedule,
                      text: dateStr,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.group_outlined,
                      text: 'Pax: ${booking.pax}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Entry Pass',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: booking.id.toString(),
                    size: 200,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

