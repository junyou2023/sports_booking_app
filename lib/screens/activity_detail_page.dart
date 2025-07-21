import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_booking_page.dart';

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final image = activity.imageUrl ?? activity.image;
    return Scaffold(
      appBar: AppBar(title: Text(activity.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        image,
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
              '\$${activity.basePrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(activity.description),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivityBookingPage(activity: activity),
                  ),
                );
              },
              child: const Text('Book now'),
            ),
          ],
        ),
      ),
    );
  }
}
