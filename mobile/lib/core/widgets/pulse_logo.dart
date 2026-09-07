import 'package:flutter/material.dart';
import 'rally_text_logo.dart';

/// Modern Typographic Brand Logo for Rally
/// Clean, bold text logo featuring the authentic perforated pickleball in the 'R'.
class PulseLogo extends StatelessWidget {
  final double size;
  final bool? isDark;
  final bool isWhite;
  final bool showSubtitle;

  const PulseLogo({
    super.key,
    this.size = 80.0,
    this.isDark,
    this.isWhite = false,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RallyTextLogo(
        fontSize: size * 0.55,
        isDark: isDark,
        isWhite: isWhite,
        showSubtitle: showSubtitle,
      ),
    );
  }
}
