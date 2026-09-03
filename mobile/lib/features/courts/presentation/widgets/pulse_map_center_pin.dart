import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';

/// Sculpted modern teardrop map pin with precision ground reticle
/// and interactive lift-and-drop micro-animation during map panning.
///
/// Designed to be placed directly in a [Center] widget above the map canvas.
/// The anchor needle tip and ground reticle automatically align to the exact
/// center coordinate of the parent without requiring manual offset adjustments.
///
/// Strictly compliant with Pulse design rules (no drop shadows, borderless fills).
class PulseMapCenterPin extends StatelessWidget {
  /// Active sport name/key (Tennis, Pickleball, Badminton, Table Tennis, etc.).
  final String sport;

  /// True when the user is actively dragging or panning the map canvas.
  final bool isDragging;

  /// Whether active view is in dark mode.
  final bool isDark;

  /// Head width size of the pin teardrop. Defaults to 44.0.
  final double size;

  const PulseMapCenterPin({
    super.key,
    this.sport = 'Tennis',
    this.isDragging = false,
    this.isDark = false,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final pinHeight = size * 1.25;

    return IgnorePointer(
      child: SizedBox(
        width: size + 20.0,
        height: 24.0,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Precision Ground Reticle Target (centered at y = 12)
            _GroundReticle(
              isDragging: isDragging,
              isDark: isDark,
            ),

            // 2. Interactive Floating Teardrop Pin (tip touches y = 12 when idle)
            Positioned(
              bottom: 12.0,
              child: AnimatedSlide(
                offset: isDragging ? const Offset(0.0, -0.22) : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: isDragging ? Curves.easeOutCubic : Curves.easeOutBack,
                child: _TeardropPinShape(
                  sport: sport,
                  size: size,
                  pinHeight: pinHeight,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Precision concentric ground reticle showing the exact targeted map coordinate.
class _GroundReticle extends StatelessWidget {
  final bool isDragging;
  final bool isDark;

  const _GroundReticle({
    required this.isDragging,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reticleSize = isDragging ? 20.0 : 12.0;
    final ringOpacity = isDragging ? 0.6 : 0.25;

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Expanding concentric target ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: reticleSize,
              height: reticleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PulseColors.primary.withValues(alpha: ringOpacity),
                  width: isDragging ? 2.0 : 1.5,
                ),
              ),
            ),
            // Solid center focal dot
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: isDark ? PulseColors.secondary : PulseColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painted teardrop pin with contrasting inner sport badge.
class _TeardropPinShape extends StatelessWidget {
  final String sport;
  final double size;
  final double pinHeight;
  final bool isDark;

  const _TeardropPinShape({
    required this.sport,
    required this.size,
    required this.pinHeight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.60;

    return SizedBox(
      width: size,
      height: pinHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Sculpted Teardrop Base
          CustomPaint(
            size: Size(size, pinHeight),
            painter: _TeardropCustomPainter(
              fillColor: PulseColors.primary,
              tipAccentColor: isDark ? PulseColors.secondary : PulseColors.textPrimary,
            ),
          ),

          // Inner Dynamic Sport Badge
          Positioned(
            top: (size - badgeSize) / 2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: isDark ? PulseColors.darkCard : Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                PulseSportIcons.getIcon(sport.toLowerCase()),
                size: badgeSize * 0.58,
                color: isDark ? Colors.white : PulseColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vector painter that renders an organic teardrop map pin silhouette.
class _TeardropCustomPainter extends CustomPainter {
  final Color fillColor;
  final Color tipAccentColor;

  _TeardropCustomPainter({
    required this.fillColor,
    required this.tipAccentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(0, r)
      ..arcToPoint(
        Offset(w, r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..cubicTo(w, r + r * 0.45, w * 0.72, h * 0.82, r, h)
      ..cubicTo(w * 0.28, h * 0.82, 0, r + r * 0.45, 0, r)
      ..close();

    canvas.drawPath(path, paint);

    // Subtle micro-tip accent to crisply terminate the needle point
    final tipPaint = Paint()
      ..color = tipAccentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(Offset(r, h - 1.5), 2.0, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _TeardropCustomPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.tipAccentColor != tipAccentColor;
  }
}
