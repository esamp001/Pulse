import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

/// Styled Modern Typographic Logo for Rally
/// Displays "RALLY" with bold modern gradient typography, centered and scale-safe.
class RallyTextLogo extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  final String? subtitleText;

  const RallyTextLogo({
    super.key,
    this.fontSize = 42.0,
    this.showSubtitle = true,
    this.subtitleText = 'Turn casual games into competitive matches',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? const [Color(0xFFFFFFFF), Color(0xFFD3F2F8), PulseColors.secondary]
        : const [Color(0xFF132B30), PulseColors.primary, PulseColors.accent];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
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
          if (showSubtitle && subtitleText != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitleText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: PulseColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
