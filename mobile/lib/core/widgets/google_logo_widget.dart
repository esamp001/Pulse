import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect 4-Color Official Google "G" Emblem Widget
/// Renders crisp vector paths for Red, Yellow, Green, and Blue segments.
class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width * 0.40;
    final double strokeWidth = size.width * 0.20;
    final Rect arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Official Google Brand Palette
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);
    const Color blue = Color(0xFF4285F4);

    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red Segment (Top Arc)
    strokePaint.color = red;
    canvas.drawArc(arcRect, -math.pi * 0.72, math.pi * 0.46, false, strokePaint);

    // 2. Yellow Segment (Left Arc)
    strokePaint.color = yellow;
    canvas.drawArc(arcRect, -math.pi * 0.98, -math.pi * 0.44, false, strokePaint);

    // 3. Green Segment (Bottom Arc)
    strokePaint.color = green;
    canvas.drawArc(arcRect, math.pi * 0.24, math.pi * 0.48, false, strokePaint);

    // 4. Blue Segment (Right Arc)
    strokePaint.color = blue;
    canvas.drawArc(arcRect, -math.pi * 0.26, math.pi * 0.50, false, strokePaint);

    // 5. Blue Horizontal Bar
    final Paint barPaint = Paint()..color = blue;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - strokeWidth / 2, size.width * 0.95, cy + strokeWidth / 2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
