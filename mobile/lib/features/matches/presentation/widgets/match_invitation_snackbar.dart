import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../models/match_model.dart';

class MatchInvitationSnackbar extends StatefulWidget {
  final MatchModel match;
  final String currentUserRoleLabel; // e.g. 'Player 2 (Opponent)' or 'Neutral Scorer'
  final bool isDarkMode;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const MatchInvitationSnackbar({
    super.key,
    required this.match,
    required this.currentUserRoleLabel,
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

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _totalSeconds;
    _startTimer();
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
    final inviterName = widget.match.player1?.name ?? 'Match Host';
    final cardBg = PulseColors.getSurface(widget.isDarkMode);
    final borderColor = PulseColors.getBorder(widget.isDarkMode);
    final textPrimary = PulseColors.getTextPrimary(widget.isDarkMode);
    final textSecondary = PulseColors.getTextSecondary(widget.isDarkMode);

    final progressValue = _secondsRemaining / _totalSeconds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar at the top edge of snackbar
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 4,
                backgroundColor: PulseColors.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _secondsRemaining <= 10 ? PulseColors.error : PulseColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PulseColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: PulseColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.sports_tennis_rounded,
                          color: PulseColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Invitation Received',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.match.sportDisplayName} • ${widget.match.venueName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Countdown timer badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (_secondsRemaining <= 10
                              ? PulseColors.error
                              : PulseColors.primary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _secondsRemaining <= 10
                                ? PulseColors.error
                                : PulseColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: _secondsRemaining <= 10
                                  ? PulseColors.error
                                  : PulseColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_secondsRemaining}s',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _secondsRemaining <= 10
                                    ? PulseColors.error
                                    : PulseColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$inviterName invited you to join as ${widget.currentUserRoleLabel}.',
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Decline Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onDecline,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.error.withValues(alpha: 0.12),
                            foregroundColor: PulseColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 13),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept & Join Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
}
