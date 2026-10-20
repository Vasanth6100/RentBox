import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Master Prompt palette
  static const Color primary = Color(0xFF006B4F); // Primary emerald green
  static const Color primaryDark = Color(0xFF005B43); // Dark green
  static const Color primaryLight = Color(0xFF0D8C68);
  static const Color mintBackground = Color(0xFFF3FAF4); // Mint background
  static const Color mintSurface = Color(0xFFE9F2EB); // Light mint surfaces
  static const Color cardWhite = Color(0xFFFFFFFF); // White cards
  static const Color textPrimary = Color(0xFF17231E); // Main text
  static const Color textSecondary = Color(0xFF65756D); // Secondary text
  static const Color borderLight = Color(0xFFE6EEE8); // Border colour

  // Status colors
  static const Color success = Color(0xFF22C55E); // Soft green
  static const Color warning = Color(0xFFF59E0B); // Soft amber
  static const Color error = Color(0xFFEF4444); // Soft red

  // Accent tones
  static const Color inputFill = Color(0xFFEEF5F0);
  static const Color textMuted = Color(0xFF8DA399);
  static const Color starYellow = Color(0xFFF59E0B);
  static const Color priceGreen = Color(0xFF006B4F);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.mintBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.cardWhite,
        surfaceContainerLowest: AppColors.mintBackground,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
