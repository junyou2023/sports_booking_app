import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String label = count > 9 ? '9+' : '$count';
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24),
            onPressed: onPressed,
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
