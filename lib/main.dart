import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/home_page.dart';

void main() {
  runApp(SportsBookingApp());
}

class SportsBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Booking',
      theme: CustomTheme.light,
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
