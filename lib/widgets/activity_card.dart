// ========== lib/widgets/activity_card.dart ==========
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String location;
  final double price;
  final double rating;
  final int reviews;
  final String asset;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 260,
        child: Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: asset,
                child: Image.asset(
                  asset,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(location,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemCount: 5,
                          itemSize: 16,
                          unratedColor: Colors.grey.shade300,
                          itemBuilder: (_, __) =>
                          const Icon(Icons.star_rounded, color: Colors.amber),
                        ),
                        const SizedBox(width: 4),
                        Text('($reviews)',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Text('\$${price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
