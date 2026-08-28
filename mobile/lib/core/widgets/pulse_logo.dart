import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

/// Modern Typographic Brand Logo for Rally
/// Clean, bold modern text logo with dynamic theme gradient, centered and scale-safe.
class PulseLogo extends StatelessWidget {
  final double size;

  const PulseLogo({
    super.key,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = (size * 0.44).clamp(16.0, 72.0);

    final gradientColors = isDark
        ? const [Color(0xFFFFFFFF), Color(0xFFD3F2F8), PulseColors.secondary]
        : const [Color(0xFF132B30), PulseColors.primary, PulseColors.accent];

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle stroke outline layer for heavier, bolder typographic weight
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'RALLY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  height: 1.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = fontSize * 0.07
                    ..strokeJoin = StrokeJoin.round
                    ..strokeCap = StrokeCap.round
                    ..color = Colors.white,
                ),
              ),
            ),
            // Inner filled text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'RALLY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
