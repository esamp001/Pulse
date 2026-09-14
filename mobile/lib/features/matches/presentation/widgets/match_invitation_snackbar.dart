import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../../courts/models/court_model.dart';
import '../../../courts/services/court_service.dart';
import '../../models/match_model.dart';

/// Modern Two-Tone Split Hero Match Invitation Card / Snackbar.
///
/// Features:
/// - Top Hero Section: Court photo with natural gradient scrim (or authentic athletic
///   sport gridline and watermark fallback), sport category, venue name, and floating mint countdown timer pill.
/// - Top edge smooth countdown decay progress bar.
/// - Bottom Surface Section: Inviter avatar with monogram fallback, inviter name, role description,
///   and borderless, zero-drop-shadow action buttons (Decline vs Accept & Join).
/// - Fully responsive for ultra-small viewports (~280dp) with zero RenderFlex overflows.
class MatchInvitationSnackbar extends StatefulWidget {
  final MatchModel match;
  final String currentUserRoleLabel; // e.g. 'Player 2 (Opponent)' or 'Neutral Scorer'
  final String? courtImageUrl;
  final bool isDarkMode;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const MatchInvitationSnackbar({
    super.key,
    required this.match,
    required this.currentUserRoleLabel,
    this.courtImageUrl,
    required this.isDarkMode,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<MatchInvitationSnackbar> createState() => _MatchInvitationSnackbarState();
}

class _MatchInvitationSnackbarState extends State<MatchInvitationSnackbar> {
  static const int _totalSeconds = 30;
  late int _secondsRemaining;
  Timer? _timer;
  String? _resolvedCourtImageUrl;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _totalSeconds;
    _resolvedCourtImageUrl = widget.courtImageUrl ?? widget.match.courtImageUrl;
    if (_resolvedCourtImageUrl == null || _resolvedCourtImageUrl!.isEmpty) {
      _fetchCourtImage();
    }
    _startTimer();
  }

  Future<void> _fetchCourtImage() async {
    final venue = widget.match.venueName.trim();
    if (venue.isEmpty) return;
    try {
      final courts = await CourtService().fetchNearbyCourts(search: venue);
      if (!mounted) return;
      final lowerVenue = venue.toLowerCase();
      CourtModel? matched;
      for (final court in courts) {
        if (court.imageUrl != null && court.imageUrl!.trim().isNotEmpty) {
          final courtName = court.name.toLowerCase();
          if (courtName == lowerVenue || courtName.contains(lowerVenue) || lowerVenue.contains(courtName)) {
            matched = court;
            break;
          }
        }
      }
      matched ??= courts.cast<CourtModel?>().firstWhere(
        (c) => c?.imageUrl != null && c!.imageUrl!.trim().isNotEmpty,
        orElse: () => null,
      );

      if (matched != null && matched.imageUrl != null && matched.imageUrl!.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _resolvedCourtImageUrl = matched!.imageUrl!.trim();
          });
        }
      }
    } catch (e) {
      debugPrint('[MatchInvitationSnackbar _fetchCourtImage Error]: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inviter = widget.match.player1;
    final inviterName = (inviter != null && inviter.name.trim().isNotEmpty)
        ? inviter.name.trim()
        : 'Match Host';
    final inviterAvatar = inviter?.avatarUrl;
    final inviterInitial = inviterName.isNotEmpty ? inviterName[0].toUpperCase() : 'H';
    final cardBg = PulseColors.getSurface(widget.isDarkMode);
    final textPrimary = PulseColors.getTextPrimary(widget.isDarkMode);
    final textSecondary = PulseColors.getTextSecondary(widget.isDarkMode);
    final progressValue = _secondsRemaining / _totalSeconds;
    final isUrgent = _secondsRemaining <= 10;
    final sportKey = widget.match.sport.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
    final effectiveCourtImageUrl = _resolvedCourtImageUrl ?? widget.courtImageUrl ?? widget.match.courtImageUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sleek decaying top countdown line
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 3,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(
              isUrgent ? PulseColors.error : const Color(0xFF34D399),
            ),
          ),

          // 2. Upper Hero Section (Court photo / Sport grid-art fallback + Title + Timer pill)
          SizedBox(
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background: Court Photo with Easing Scrim OR Athletic Sport Grid Fallback
                if (effectiveCourtImageUrl != null && effectiveCourtImageUrl.trim().isNotEmpty)
                  Image.network(
                    effectiveCourtImageUrl.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildSportGraphicFallback(widget.isDarkMode, sportKey),
                  )
                else
                  _buildSportGraphicFallback(widget.isDarkMode, sportKey),

                // Natural Gradient Overlay for crisp legibility
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.40),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Hero Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Category Label & Floating Countdown Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Flexible(
                            child: Text(
                              'MATCH INVITATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Mint Accent Timer Pill (Urgent Red when <= 10s)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? PulseColors.error.withValues(alpha: 0.95)
                                  : const Color(0xFFD4F7DC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: isUrgent ? Colors.white : const Color(0xFF0C3E37),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_secondsRemaining}s',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isUrgent ? Colors.white : const Color(0xFF0C3E37),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Bottom of Header: Sport Title & Location
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.match.sportDisplayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.match.venueName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Lower Section: Inviter Info & Borderless Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Inviter Avatar & Detail Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: PulseColors.primary.withValues(alpha: 0.12),
                      backgroundImage: (inviterAvatar != null && inviterAvatar.trim().isNotEmpty)
                          ? NetworkImage(inviterAvatar.trim())
                          : null,
                      child: (inviterAvatar == null || inviterAvatar.trim().isEmpty)
                          ? Text(
                              inviterInitial,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: PulseColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inviterName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'invited you to join as\n${widget.currentUserRoleLabel}.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Borderless Action Buttons: Decline vs Accept & Join
                Row(
                  children: [
                    // Decline Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onDecline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.error.withValues(alpha: 0.09),
                          foregroundColor: PulseColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Accept & Join Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Accept & Join',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an authentic athletic sport fallback banner with court grid lines and watermark icon
  Widget _buildSportGraphicFallback(bool isDark, String sportKey) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF143B37),
            Color(0xFF0C2422),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background court grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtGridLinePainter(
                lineColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Stylized sport watermark icon
          Positioned(
            right: -10,
            bottom: -14,
            child: Opacity(
              opacity: 0.18,
              child: PulseSportIcons.buildWidget(
                sportKey,
                size: 90,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight painter for athletic court grid lines
class _CourtGridLinePainter extends CustomPainter {
  final Color lineColor;

  const _CourtGridLinePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Stylized outer court perimeter
    final courtRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(6),
    );
    canvas.drawRRect(courtRect, paint);

    // Center divider / net line
    canvas.drawLine(
      Offset(size.width / 2, 10),
      Offset(size.width / 2, size.height - 10),
      paint,
    );

    // Horizontal service divide
    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtGridLinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
