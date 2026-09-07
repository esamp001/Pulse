import 'package:flutter/material.dart';

/// Official Brand Logo Widget for Rally
/// Displays the authentic high-resolution logo asset from the design team:
/// - assets/images/logo_rally_white.png on dark backgrounds
/// - assets/images/logo_rally_official.png on light backgrounds
class RallyTextLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool? isDark;
  final bool isWhite;
  final bool showSubtitle;

  const RallyTextLogo({
    super.key,
    this.fontSize = 32.0,
    this.color,
    this.isDark,
    this.isWhite = false,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final bool useWhiteLogo = isWhite || effectiveIsDark;

    // Aspect ratio of official logo is 2152 / 731 = 2.9439
    final double height = fontSize * 1.15;
    final double width = height * (2152.0 / 731.0);

    final assetPath = useWhiteLogo
        ? 'assets/images/logo_rally_white.png'
        : 'assets/images/logo_rally_official.png';

    Widget logoImage = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );

    if (color != null) {
      logoImage = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: logoImage,
      );
    }

    return logoImage;
  }
}
