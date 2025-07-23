// ========== lib/widgets/project_card.dart ==========
import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double price;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.onTap,
  });

  Widget _buildImage() {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
      );
    }
    return Image.asset(imageUrl, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(),
            ),
          ),
          const SizedBox(height: 18),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('\$${price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}