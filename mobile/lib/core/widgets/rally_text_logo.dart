import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pulse_colors.dart';

/// Official Brand Logo Widget for Rally
/// Displays the authentic high-resolution logo asset:
/// - assets/images/LOGO RALLY - OFFICIAL.png
/// Includes graceful vector fallback if asset is pending bundle rebuild.
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

    // Aspect ratio of official logo is 1696 / 520 = 3.2615
    final double height = fontSize * 1.15;
    final double width = height * (1696.0 / 520.0);

    const assetPath = 'assets/images/LOGO_RALLY.png';

    Widget logoImage = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildVectorFallback(effectiveIsDark, useWhiteLogo);
      },
    );

    if (color != null) {
      logoImage = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: logoImage,
      );
    } else if (!useWhiteLogo) {
      // On light backgrounds, tint white letters to dark brand teal
      logoImage = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF163A42), BlendMode.srcIn),
        child: logoImage,
      );
    }

    return logoImage;
  }

  Widget _buildVectorFallback(bool effectiveIsDark, bool useWhiteLogo) {
    final Color textColor = useWhiteLogo
        ? Colors.white
        : (color ?? (effectiveIsDark ? PulseColors.darkTextPrimary : PulseColors.textPrimary));

    final Color ballBg = useWhiteLogo
        ? const Color(0xFF132B30)
        : (effectiveIsDark ? const Color(0xFF1D2C2F) : PulseColors.accent);

    final ballDiameter = fontSize * 0.38;
    final ballLeft = fontSize * 0.17;
    final ballTop = fontSize * 0.14;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
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
                  painter: _PickleballHolesPainter(dotColor: Colors.white),
                ),
              ),
            ),
          ],
        ),
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

    canvas.drawCircle(center, dotRadius, paint);

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
