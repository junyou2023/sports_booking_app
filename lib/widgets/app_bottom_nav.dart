// ========== lib/widgets/app_bottom_nav.dart ==========
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bookings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primary.withOpacity(.1),
      elevation: 3,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}
