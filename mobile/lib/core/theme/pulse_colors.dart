import 'package:flutter/material.dart';

/// Pulse Application Brand Colors
abstract class PulseColors {
  // Palette Core Colors
  static const Color text = Color(0xFF0B1213);          // Main dark text (#0b1213)
  static const Color background = Color(0xFFF2F7F8);    // Main screen background (#f2f7f8)
  static const Color primary = Color(0xFF2A525A);       // Deep Teal Primary (#2a525a)
  static const Color secondary = Color(0xFF88C2CD);     // Soft Cyan Secondary (#88c2cd)
  static const Color accent = Color(0xFF3A92A1);        // Vibrant Teal Accent (#3a92a1)

  // Surface & Card Colors
  static const Color surface = Color(0xFFFFFFFF);       // Cards, dialogs, bottom sheets
  static const Color card = Color(0xFFFAFCFD);          // Subtle card tint
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
  static const Color border = Color(0xFFD6E5E8);        // Outlines and dividers
}
