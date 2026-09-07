import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Screen 1: Official Get Started Onboarding Screen
/// Deep athletic dark teal canvas with authentic perspective court lines,
/// pickleball ball on the line, official white Rally logo, and cyan CTA.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF14373E); // Deep dark athletic teal canvas
    const cyanAccent = Color(0xFF35AFC2); // Electric cyan accent
    const mutedText = Color(0xFF98ADB0); // Soft muted teal-gray

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Background Photo Asset
          Positioned.fill(
            child: Image.asset(
              'assets/images/get-started-bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Scrim Overlay for optimal text readability and contrast
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Main Foreground Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxHeight < 560;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 20.0 : 28.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmall ? 24 : 64),

                      // Unified Primary Header Container grouping Logo and Tagline with flush left alignment
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Official Rally White Logo: scaled to ~70% of screen width
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: constraints.maxWidth * 0.68,
                                child: Image.asset(
                                  'assets/images/LOGO_RALLY.png',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: _RallyWhiteLogo(
                                        fontSize: isSmall ? 44.0 : 62.0,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: isSmall ? 10 : 16),

                            // Tagline
                            Text(
                              'PLAY. CONNECT. RALLY.',
                              style: GoogleFonts.lexend(
                                fontSize: isSmall ? 11.5 : 13.0,
                                fontWeight: FontWeight.w800,
                                color: cyanAccent,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmall ? 10 : 14),

                      // Description
                      Text(
                        'Find courts, join games,\nand meet players near you.\nAll in one place.',
                        style: GoogleFonts.lexend(
                          fontSize: isSmall ? 13.5 : 15.0,
                          fontWeight: FontWeight.w400,
                          color: mutedText,
                          height: 1.45,
                        ),
                      ),

                      const Spacer(),

                      // Action Button: "Get Started  →"
                      SizedBox(
                        width: double.infinity,
                        height: isSmall ? 44 : 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cyanAccent,
                            foregroundColor: const Color(0xFF0B1E21),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.lexend(
                                    fontSize: isSmall ? 14.5 : 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B1E21),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Color(0xFF0B1E21),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 14 : 20),

                      // Footer: I Already Have an Account
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'I Already Have an Account',
                              style: GoogleFonts.lexend(
                                fontSize: isSmall ? 12.0 : 13.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 12 : 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback vector logo matching LOGO_RALLY.png exactly
class _RallyWhiteLogo extends StatelessWidget {
  final double fontSize;

  const _RallyWhiteLogo({this.fontSize = 44.0});

  @override
  Widget build(BuildContext context) {
    final ballDiameter = fontSize * 0.36;
    final ballLeft = fontSize * 0.165;
    final ballTop = fontSize * 0.155;

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
                color: Colors.white,
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF268C9E),
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
            color: Colors.white,
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
    final dotRadius = (size.width * 0.08).clamp(0.8, 2.5);

    canvas.drawCircle(center, dotRadius, paint);

    final ringRadius = size.width * 0.28;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3.0) + (math.pi / 6.0);
      final offset = Offset(
        center.dx + ringRadius * math.cos(angle),
        center.dy + ringRadius * math.sin(angle),
      );
      canvas.drawCircle(offset, dotRadius * 0.85, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickleballHolesPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}

