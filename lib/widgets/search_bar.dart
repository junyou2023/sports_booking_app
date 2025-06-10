// ========== lib/widgets/search_bar.dart ==========
import 'dart:ui';
import 'package:flutter/material.dart';

class RoundedSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final double height;

  const RoundedSearchBar({
    super.key,
    this.onTap,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(height / 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: BackdropFilter(          // 轻磨砂，提升质感
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              height: height,
              padding: const EdgeInsets.only(left: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 22, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    'Find places and things to do',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
