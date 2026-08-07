import 'package:flutter/material.dart';

/// Reusable Rally Official Logo Component (Dog + Ball Mascot Logo)
class PulseLogo extends StatelessWidget {
  final double size;

  const PulseLogo({
    super.key,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/official_logo_rally.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
