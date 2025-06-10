// ========== lib/utils/theme.dart ==========
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0057FF);
  static const Color secondary = Color(0xFFFF6B00);
  static const Color background = Color(0xFFF8F9FA);

  /// Material 3 Light Theme
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.nunito(
            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
        titleLarge: GoogleFonts.nunito(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        bodyLarge:
        GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade900),
        bodyMedium:
        GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle:
          GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
