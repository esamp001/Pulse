import 'package:flutter/material.dart';

/// Reusable Pulse Logo Component
class PulseLogo extends StatelessWidget {
  final double size;

  const PulseLogo({
    super.key,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/pulse_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
