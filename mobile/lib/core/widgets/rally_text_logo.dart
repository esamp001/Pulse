import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

/// Styled Typographic Logo for Rally
/// Displays "RALLY" as a sleek, modern brand logo using gradient typography.
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Typographic Ultra-Bold Gradient Brand Logo
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer stroke layer for extra bold weight
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? const [Color(0xFFFFFFFF), PulseColors.secondary, PulseColors.accent]
                    : const [PulseColors.primary, PulseColors.accent, Color(0xFF0F2428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'RALLY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = fontSize * 0.05
                    ..color = Colors.white,
                ),
              ),
            ),
            // Inner filled text layer
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? const [Color(0xFFE0F7FA), PulseColors.secondary, PulseColors.accent]
                    : const [PulseColors.primary, PulseColors.accent, Color(0xFF1E3A40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'RALLY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (showSubtitle && subtitleText != null) ...[
          const SizedBox(height: 6),
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
    );
  }
}
