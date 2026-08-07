import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pulse_colors.dart';

/// Pulse Application ThemeData Configuration
abstract class PulseTheme {
  static TextTheme _buildSourceCodeProTextTheme(bool isDark) {
    final textPrimary = PulseColors.getTextPrimary(isDark);
    final textSecondary = PulseColors.getTextSecondary(isDark);

    return GoogleFonts.sourceCodeProTextTheme(
      TextTheme(
        // h1: 67.36px (4.210rem), 700 bold
        displayLarge: TextStyle(fontSize: 67.36, fontWeight: FontWeight.w700, color: textPrimary),
        // h2: 50.56px (3.158rem), 700 bold
        displayMedium: TextStyle(fontSize: 50.56, fontWeight: FontWeight.w700, color: textPrimary),
        // h3: 37.92px (2.369rem), 700 bold
        displaySmall: TextStyle(fontSize: 37.92, fontWeight: FontWeight.w700, color: textPrimary),
        // h4: 28.48px (1.777rem), 700 bold
        headlineMedium: TextStyle(fontSize: 28.48, fontWeight: FontWeight.w700, color: textPrimary),
        // h5: 21.28px (1.333rem), 700 bold
        headlineSmall: TextStyle(fontSize: 21.28, fontWeight: FontWeight.w700, color: textPrimary),
        // body / paragraph: 16px (1.0rem), 400 regular
        bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400, color: textPrimary),
        // small: 12px (0.75rem), 400 regular
        bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: textSecondary),
        labelSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: textSecondary),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PulseColors.background,
      fontFamily: GoogleFonts.sourceCodePro().fontFamily,
      textTheme: _buildSourceCodeProTextTheme(false),

      colorScheme: const ColorScheme.light(
        primary: PulseColors.primary,
        secondary: PulseColors.secondary,
        surface: PulseColors.surface,
        error: PulseColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: PulseColors.textPrimary,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: PulseColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: PulseColors.textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: PulseColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PulseColors.border, width: 1),
        ),
      ),

      // Input Decoration Theme (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PulseColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: PulseColors.textSecondary),
        labelStyle: const TextStyle(color: PulseColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.error),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PulseColors.darkBackground,
      fontFamily: GoogleFonts.sourceCodePro().fontFamily,
      textTheme: _buildSourceCodeProTextTheme(true),

      colorScheme: const ColorScheme.dark(
        primary: PulseColors.secondary,
        secondary: PulseColors.accent,
        surface: PulseColors.darkSurface,
        error: PulseColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: PulseColors.darkTextPrimary,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.darkBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: PulseColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: PulseColors.darkTextPrimary),
      ),

      cardTheme: CardThemeData(
        color: PulseColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PulseColors.darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
