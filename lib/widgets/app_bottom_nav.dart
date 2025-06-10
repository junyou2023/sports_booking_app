// ========== lib/widgets/app_bottom_nav.dart ==========
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Material-3 风格底栏：Icon + Label，全局 4 个目的地
class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // —— 构造带徽标的图标 —— //
    Widget _icon(IconData outlined, IconData filled,
        {required bool selected, int badge = 0}) {
      final icon = Icon(
        selected ? filled : outlined,
        size: 26,
        color: selected ? AppTheme.primary : Colors.black54,
      );

      // 如需徽标
      if (badge == 0) return icon;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              padding: const EdgeInsets.all(2),
              child: Text('$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }

    return NavigationBar(
      height: 72,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primary.withOpacity(.12),          // 圆形水滴
      surfaceTintColor: Colors.white,
      selectedIndex: index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: _icon(Icons.home_outlined, Icons.home,
              selected: index == 0),
          label: 'Home',
        ),
        NavigationDestination(
          icon: _icon(Icons.favorite_outline, Icons.favorite,
              selected: index == 1, badge: 2), // 示范红点
          label: 'Favorites',
        ),
        NavigationDestination(
          icon: _icon(Icons.inbox_outlined, Icons.inbox,
              selected: index == 2),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: _icon(Icons.person_outline, Icons.person,
              selected: index == 3),
          label: 'Profile',
        ),
      ],
    );
  }
}
