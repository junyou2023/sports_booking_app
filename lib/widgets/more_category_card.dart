// ========== lib/widgets/more_category_card.dart ==========
import 'package:flutter/material.dart';

/// 横向列表最后一个“More”卡片：边框 + 三点图标
class MoreCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  const MoreCategoryCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 1.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.more_horiz, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text('More',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
