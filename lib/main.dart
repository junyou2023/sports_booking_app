// lib/main.dart
import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/home_page.dart';

void main() => runApp(const SportsBookingApp());

class SportsBookingApp extends StatelessWidget {
  const SportsBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Booking',
      theme: AppTheme.light,            // ⇦ 使用新的主题类
      debugShowCheckedModeBanner: false,
      home: const HomePage(),           // ⇦ 首页
    );
  }
}
