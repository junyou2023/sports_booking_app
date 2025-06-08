import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: Colors.orange,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    );
  }
}
