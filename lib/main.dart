import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'utils/theme.dart';

void main() {
  runApp(SportsBookingApp());
}

class SportsBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sports Booking',
      theme: CustomTheme.lightTheme,
      home: HomePage(),
    );
  }
}
