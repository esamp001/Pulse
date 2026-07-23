import 'package:flutter/material.dart';
import 'pulse_colors.dart';

/// Pulse Application ThemeData Configuration
abstract class PulseTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PulseColors.background,

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
        elevation: 1,
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
          borderSide: const BorderSide(color: PulseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.border),
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
