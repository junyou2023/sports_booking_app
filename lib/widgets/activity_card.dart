// lib/widgets/activity_card.dart
// -- 既支持本地 asset，又支持网络 URL 的卡片 ---------------------------
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String location;
  final double price;
  final double rating;
  final int reviews;
  final String asset;            // 本地或网络路径
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

  // ----- 私有：生成图片组件，自动判断网络 / 本地 -------------------------
  Widget _buildHeroImage() {
    if (asset.startsWith('http')) {
      return Image.network(
        asset,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Colors.black12,
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
    }
    return Image.asset(
      asset,
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
              Expanded(                                     // 防止溢出
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(location, style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
