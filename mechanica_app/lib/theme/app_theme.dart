import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF121212);
  static const Color primaryRed = Color(0xFFE52C27); // Mechanica Red
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color inputBackground = Color(0xFF2A2A2A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryRed,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        background: backgroundColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          bodyLarge: const TextStyle(color: textPrimary),
          bodyMedium: const TextStyle(color: textSecondary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}
