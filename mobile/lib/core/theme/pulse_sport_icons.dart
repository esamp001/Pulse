import 'package:flutter/material.dart';

/// Centralized sport icon & asset mappings for Pulse mobile application.
/// Ensures consistent sport image asset representation across all screens
/// (Create Match, Home Sport Preferences, Onboarding, Rankings, etc.).
class PulseSportIcons {
  PulseSportIcons._();

  // Standardized PNG Image Asset Paths
  static const String pickleballAsset = 'assets/images/pickle-ball.png';
  static const String tennisAsset = 'assets/images/tennis.png';
  static const String tableTennisAsset = 'assets/images/table-tennis.png';
  static const String badmintonAsset = 'assets/images/badminton.png';

  /// Returns the standardized PNG asset path for a given sport key string.
  static String getAssetPath(String sportKey) {
    final normalized = sportKey.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
    switch (normalized) {
      case 'pickleball':
        return pickleballAsset;
      case 'tennis':
        return tennisAsset;
      case 'table_tennis':
      case 'tabletennis':
      case 'ping_pong':
        return tableTennisAsset;
      case 'badminton':
        return badmintonAsset;
      default:
        return tennisAsset;
    }
  }

  /// Builds a Widget rendering the PNG image asset (or fallback IconData) for the sport.
  static Widget buildWidget(
    String sportKey, {
    double size = 44,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    final path = getAssetPath(sportKey);
    return Image.asset(
      path,
      width: size,
      height: size,
      color: color,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Icon(
        getIcon(sportKey),
        size: size,
        color: color,
      ),
    );
  }

  /// Pickleball: Paddle representation (FontAwesome fa-table-tennis-paddle-ball 0xf45d)
  static const IconData pickleball = IconData(
    0xf45d,
    fontFamily: 'FontAwesomeSolid',
    fontPackage: 'font_awesome_flutter',
  );

  /// Tennis: Official Tennis Ball icon (FontAwesome fa-tennis-ball 0xf45e)
  static const IconData tennis = IconData(
    0xf45e,
    fontFamily: 'FontAwesomeSolid',
    fontPackage: 'font_awesome_flutter',
  );

  /// Table Tennis: Official Table Tennis Paddle & Ball icon (FontAwesome fa-table-tennis-paddle-ball 0xf45d)
  static const IconData tableTennis = IconData(
    0xf45d,
    fontFamily: 'FontAwesomeSolid',
    fontPackage: 'font_awesome_flutter',
  );

  /// Badminton: Official Shuttlecock icon (FontAwesome fa-shuttlecock 0xf45b)
  static const IconData badminton = IconData(
    0xf45b,
    fontFamily: 'FontAwesomeSolid',
    fontPackage: 'font_awesome_flutter',
  );

  /// Returns the standardized icon for a given sport key string.
  static IconData getIcon(String sportKey) {
    final normalized = sportKey.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
    switch (normalized) {
      case 'pickleball':
        return pickleball;
      case 'tennis':
        return tennis;
      case 'table_tennis':
      case 'tabletennis':
      case 'ping_pong':
        return tableTennis;
      case 'badminton':
        return badminton;
      default:
        return Icons.sports_rounded;
    }
  }
}

