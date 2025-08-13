// lib/widgets/slot_card.dart
import 'package:flutter/material.dart';
import '../models/slot.dart';

import '../utils/image_resolver.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.onTap,
    this.selected = false,
  });

  final Slot slot;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Card(
          clipBehavior: Clip.hardEdge,
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
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

/// Smart image widget supporting network/local sources with fallback
class _SmartImage extends StatelessWidget {
  const _SmartImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    var path = url.isNotEmpty ? url : 'assets/images/hiking.jpg';
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: appImage(
        path,
        fit: BoxFit.cover,
      ),
    );
  }
}
