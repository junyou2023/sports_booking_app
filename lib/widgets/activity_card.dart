// lib/widgets/activity_card.dart
// -- Card supporting both local assets and network URLs ---------------------------
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../utils/image_resolver.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String location;
  final double price;
  final double rating;
  final int reviews;
  final String asset;            // Local or network path
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const ActivityCard({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.asset,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
  });

  // ----- Private: build image widget, automatically choose network/local ------
  Widget _buildHeroImage() {
    var path = asset.isNotEmpty ? asset : 'assets/images/default.jpg';
    path = resolveImageUrl(path);
    if (path.startsWith('http')) {
      return Image.network(
        path,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/default.jpg',
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      path,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

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
              Stack(
                children: [
                  Hero(tag: asset, child: _buildHeroImage()),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_outline,
                        color: Colors.red,
                      ),
                      onPressed: onFavorite,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(location, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemCount: 5,
                          itemSize: 16,
                          unratedColor: Colors.grey.shade300,
                          itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                        ),
                        const SizedBox(width: 4),
                        Text('($reviews)', style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Text('\$${price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
