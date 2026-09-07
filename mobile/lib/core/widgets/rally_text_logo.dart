import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pulse_colors.dart';

/// Official Typographic Logo Widget for Rally
/// Renders the signature "Rally" wordmark featuring the perforated pickleball
/// inside the upper bowl/loop of the capital letter "R".
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
    final Color textColor = isWhite
        ? Colors.white
        : (color ?? (effectiveIsDark ? PulseColors.darkTextPrimary : PulseColors.textPrimary));

    // Ball background and dot accents matching brand mockups
    final Color ballBg = isWhite
        ? const Color(0xFF132B30) // Dark background fill on dark canvas
        : (effectiveIsDark ? const Color(0xFF1D2C2F) : PulseColors.accent); // Teal/cyan on light canvas
    final Color dotColor = Colors.white;

    final ballDiameter = fontSize * 0.38;
    final ballLeft = fontSize * 0.17;
    final ballTop = fontSize * 0.14;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Capital 'R' with perforated pickleball inside the loop
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              'R',
              style: GoogleFonts.lexend(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            Positioned(
              left: ballLeft,
              top: ballTop,
              child: Container(
                width: ballDiameter,
                height: ballDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ballBg,
                ),
                child: CustomPaint(
                  size: Size(ballDiameter, ballDiameter),
                  painter: _PickleballHolesPainter(dotColor: dotColor),
                ),
              ),
            ),
          ],
        ),
        // Lowercase 'ally'
        Text(
          'ally',
          style: GoogleFonts.lexend(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the 7 pickleball hole perforations
class _PickleballHolesPainter extends CustomPainter {
  final Color dotColor;

  const _PickleballHolesPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final dotRadius = (size.width * 0.08).clamp(1.0, 3.0);

    // Center dot
    canvas.drawCircle(center, dotRadius, paint);

    // 6 surrounding dots in hexagonal pattern
    final ringRadius = size.width * 0.28;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3.0) + (math.pi / 6.0);
      final offset = Offset(
        center.dx + ringRadius * math.cos(angle),
        center.dy + ringRadius * math.sin(angle),
      );
      canvas.drawCircle(offset, dotRadius * 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickleballHolesPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}
