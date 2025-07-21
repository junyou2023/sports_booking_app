// lib/widgets/slot_card.dart
import 'package:flutter/material.dart';
import '../models/slot.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.onTap,
  });

  final Slot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SmartImage(url: slot.sport.banner),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(slot.location,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('\$${slot.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seats left: ${slot.seatsLeft}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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

/// 智能图片组件：支持网络 / 本地，并始终回退到占位图
class _SmartImage extends StatelessWidget {
  const _SmartImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    // 若为空，直接使用占位路径（防御性）
    final path = url.isNotEmpty ? url : 'assets/images/hiking.jpg';
    final isRemote = path.startsWith('http');

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: isRemote
          ? Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/sailing.jpg', fit: BoxFit.cover),
      )
          : Image.asset(path, fit: BoxFit.cover),
    );
  }
}
