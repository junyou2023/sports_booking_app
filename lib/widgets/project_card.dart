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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
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