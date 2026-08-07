import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../models/match_model.dart';

class PostMatchScreen extends StatelessWidget {
  final MatchModel match;
  final String currentUserId;

  const PostMatchScreen({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWinnerP1 = match.winnerId == match.player1Id;
    final winnerName = isWinnerP1
        ? (match.player1?.name ?? 'Player 1')
        : (match.player2?.name ?? 'Player 2');

    return Scaffold(
      backgroundColor: PulseColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: PulseColors.getTextPrimary(isDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post Match',
          style: TextStyle(
            color: PulseColors.getTextPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sport Header Pill & Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      PulseSportIcons.getIcon(match.sport),
                      color: PulseColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.sportDisplayName,
                            style: TextStyle(
                              color: PulseColors.getTextPrimary(isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            match.venueName,
                            style: TextStyle(
                              color: PulseColors.getTextSecondary(isDark),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'POST MATCH',
                        style: TextStyle(
                          color: PulseColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Match Winner & Outcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$winnerName Won!',
                        style: TextStyle(
                          color: PulseColors.getTextPrimary(isDark),
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scorer: ${match.scorer?.name ?? "Official Scorer"}',
                      style: TextStyle(
                        color: PulseColors.getTextSecondary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.getBackground(isDark),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Final Score: ${match.player1SetsWon} - ${match.player2SetsWon} Sets',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: PulseColors.getTextPrimary(isDark),
                            ),
                          ),
                          if (match.setScores != null &&
                              match.setScores!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              match.setScores!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PulseColors.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Players Versus Section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isWinnerP1
                                    ? PulseColors.accent
                                    : PulseColors.getSurface(isDark),
                                child: Text(
                                  match.player1?.initials ?? 'P1',
                                  style: TextStyle(
                                    color: isWinnerP1
                                        ? Colors.white
                                        : PulseColors.getTextPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                match.player1?.name ?? 'Player 1',
                                style: TextStyle(
                                  color: PulseColors.getTextPrimary(isDark),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: PulseColors.getTextSecondary(isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: !isWinnerP1
                                    ? PulseColors.accent
                                    : PulseColors.getSurface(isDark),
                                child: Text(
                                  match.player2?.initials ?? 'P2',
                                  style: TextStyle(
                                    color: !isWinnerP1
                                        ? Colors.white
                                        : PulseColors.getTextPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                match.player2?.name ?? 'Player 2',
                                style: TextStyle(
                                  color: PulseColors.getTextPrimary(isDark),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Match Action Button (All 3 participants)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'LEAVE MATCH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
