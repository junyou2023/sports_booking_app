// ========== lib/utils/theme.dart ==========
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 统一色板
  static const Color primary = Color(0xFF0057FF);
  static const Color secondary = Color(0xFFFF6B00);

  /// Material 3 Light
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(
            fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black),
        titleLarge: GoogleFonts.nunito(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        bodyLarge:
        GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade900),
        bodyMedium:
        GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade700),
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
          GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
