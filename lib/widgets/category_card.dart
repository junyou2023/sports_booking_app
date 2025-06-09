// ========== lib/widgets/category_card.dart ==========
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String asset;
  final VoidCallback onTap;
  const CategoryCard(
      {super.key, required this.title, required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(asset, width: 96, height: 96, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
