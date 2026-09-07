import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/rally_text_logo.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Screen 1: Official Get Started Onboarding Screen
/// Displays deep athletic teal canvas with geometric court lines,
/// signature Rally logo, sports tagline, and Get Started / Login navigation.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF132B30); // Deep dark athletic teal
    const cyanAccent = Color(0xFF35AFC2); // Electric cyan accent
    const mutedText = Color(0xFF91A4A7); // Soft muted teal-gray

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Background Geometric Court Lines with Pickleball Motif
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtLinesBackgroundPainter(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxHeight < 560;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmall ? 40 : 80),

                      // Logo
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RallyTextLogo(
                          fontSize: 52,
                          isWhite: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tagline
                      Text(
                        'PLAY. CONNECT. RALLY.',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: cyanAccent,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Find courts, join games,\nand meet players near you.',
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: mutedText,
                          height: 1.45,
                        ),
                      ),

                      const Spacer(),

                      // Action Button: "Get Started  →"
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                            foregroundColor: const Color(0xFF0B1B1E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B1B1E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Color(0xFF0B1B1E),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Footer: Already have an account? Log in
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: mutedText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Log in',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: cyanAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 16 : 28),
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

/// Custom painter to render minimalistic court lines across the dark canvas
class _CourtLinesBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1F434B) // Subtle cyan-teal stroke
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Court Line 1: Diagonal across mid section
    final path1 = Path()
      ..moveTo(-20, h * 0.65)
      ..lineTo(w * 0.62, h * 0.44)
      ..lineTo(w + 20, h * 0.54);
    canvas.drawPath(path1, linePaint);

    // Court Line 2: Intersecting boundary
    final path2 = Path()
      ..moveTo(w * 0.45, h * 0.60)
      ..lineTo(w * 0.25, h * 0.82)
      ..lineTo(-20, h * 0.88);
    canvas.drawPath(path2, linePaint);

    // Court Line 3: Lower right baseline
    final path3 = Path()
      ..moveTo(w * 0.62, h * 0.44)
      ..lineTo(w * 0.52, h * 0.72)
      ..lineTo(w * 0.78, h * 0.95);
    canvas.drawPath(path3, linePaint);

    // Court Line 4: Transverse line
    final path4 = Path()
      ..moveTo(w * 0.52, h * 0.72)
      ..lineTo(w + 20, h * 0.78);
    canvas.drawPath(path4, linePaint);

    // Pickleball Motif on the court line intersection (around w * 0.60, h * 0.59)
    final ballCenter = Offset(w * 0.60, h * 0.59);
    final ballRadius = 16.0;

    final ballBgPaint = Paint()
      ..color = const Color(0xFF132B30)
      ..style = PaintingStyle.fill;
    final ballStrokePaint = Paint()
      ..color = const Color(0xFF35AFC2)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(ballCenter, ballRadius, ballBgPaint);
    canvas.drawCircle(ballCenter, ballRadius, ballStrokePaint);

    // Pickleball hole perforations
    final dotPaint = Paint()
      ..color = const Color(0xFF35AFC2)
      ..style = PaintingStyle.fill;

    // Center dot
    canvas.drawCircle(ballCenter, 2.0, dotPaint);

    // 6 surrounding dots
    final ringR = ballRadius * 0.55;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3.0);
      final offset = Offset(
        ballCenter.dx + ringR * math.cos(angle),
        ballCenter.dy + ringR * math.sin(angle),
      );
      canvas.drawCircle(offset, 1.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
