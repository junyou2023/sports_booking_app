// ========== lib/widgets/project_card.dart ==========
import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const ProjectCard(
      {super.key, required this.title, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(imageUrl,
                  width: 180, height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
