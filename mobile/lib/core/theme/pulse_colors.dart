import 'package:flutter/material.dart';

/// Pulse Application Brand Colors
abstract class PulseColors {
  // Palette Core Colors
  static const Color text = Color(0xFF0B1213);          // Main dark text (#0b1213)
  static const Color background = Color(0xFFEBF4F6);    // Pastel Ice Cyan Background matching cards palette (#ebf4f6)
  static const Color primary = Color(0xFF2A525A);       // Deep Teal Primary (#2a525a)
  static const Color secondary = Color(0xFF88C2CD);     // Soft Cyan Secondary (#88c2cd)
  static const Color accent = Color(0xFF3A92A1);        // Vibrant Teal Accent (#3a92a1)

  // Surface & Card Colors
  static const Color surface = Color(0xFFFFFFFF);       // Cards, dialogs, bottom sheets (#ffffff)
  static const Color card = Color(0xFFF4F9FA);          // Subtle card tint (#f4f9fa)
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text & Content Aliases
  static const Color textPrimary = Color(0xFF0B1213);   // Alias for text
  static const Color textSecondary = Color(0xFF536366); // Muted Teal-Grey Text
  static const Color textDisabled = Color(0xFF91A1A4);  // Disabled Text

  // Status & Notifications
  static const Color success = Color(0xFF3A92A1);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);

  // Borders & Dividers
  static const Color border = Color(0xFFA3C6CD);        // Soft cyan border matching cards palette (#a3c6cd)

  
  // Dark Mode Palette Colors
  static const Color darkBackground = Color(0xFF0F1718);
  static const Color darkSurface = Color(0xFF182426);
  static const Color darkCard = Color(0xFF1D2C2F);
  static const Color darkTextPrimary = Color(0xFFF2F7F8);
  static const Color darkTextSecondary = Color(0xFF91A4A7);
  static const Color darkBorder = Color(0xFF2E4549);

  // Dynamic helper methods
  static Color getBackground(bool isDark) => isDark ? darkBackground : background;
  static Color getSurface(bool isDark) => isDark ? darkSurface : surface;
  static Color getCard(bool isDark) => isDark ? darkCard : card;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : textSecondary;
  static Color getBorder(bool isDark) => isDark ? darkBorder : border;
}
