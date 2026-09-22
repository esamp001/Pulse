import 'package:flutter/material.dart';

/// Centralized sport icon & asset mappings for Pulse mobile application.
/// Ensures consistent sport image asset representation across all screens
/// (Create Match, Home Sport Preferences, Onboarding, Rankings, etc.).
class PulseSportIcons {
  PulseSportIcons._();

  // Standardized PNG Image Asset Paths
  static const String pickleballAsset = 'assets/images/PICKLE-BALL-ASSET.png';
  static const String tennisAsset = 'assets/images/TENNIS-ASSET.png';
  static const String tableTennisAsset = 'assets/images/TABLE-TENNIS-ASSET.png';
  static const String badmintonAsset = 'assets/images/BADMINTON-ASSET.png';

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

  /// Pickleball: Paddle representation (Material sports_tennis_rounded)
  static const IconData pickleball = Icons.sports_tennis_rounded;

  /// Tennis: Official Tennis icon (Material sports_tennis_rounded)
  static const IconData tennis = Icons.sports_tennis_rounded;

  /// Table Tennis: Official Table Tennis Paddle & Ball icon (Material sports_tennis_rounded)
  static const IconData tableTennis = Icons.sports_tennis_rounded;

  /// Badminton: Shuttlecock / sports fallback icon (Material sports_baseball_rounded)
  static const IconData badminton = Icons.sports_baseball_rounded;

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

