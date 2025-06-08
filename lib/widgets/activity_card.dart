import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String location;
  final double price;
  final double rating;
  final int reviews;
  final String imageAsset;
  final VoidCallback onTap;

  const ActivityCard({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageAsset,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.asset(imageAsset, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: rating,
                        itemCount: 5,
                        itemSize: 18,
                        direction: Axis.horizontal,
                        itemBuilder: (_, __) => Icon(Icons.star, color: Colors.amber),
                      ),
                      SizedBox(width: 6),
                      Text('$rating', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 6),
                      Text('($reviews reviews)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('\$$price',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
