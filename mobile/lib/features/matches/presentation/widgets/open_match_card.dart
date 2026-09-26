import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../models/match_model.dart';

class OpenMatchCard extends StatelessWidget {
  final MatchModel match;
  final bool isDarkMode;
  final VoidCallback onJoin;
  final VoidCallback? onTap;
  final bool isJoining;

  const OpenMatchCard({
    super.key,
    required this.match,
    required this.isDarkMode,
    required this.onJoin,
    this.onTap,
    this.isJoining = false,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final host = match.player1;
    final court = match.court;
    final distanceText = court?.formattedDistance ?? '';
    final imageUrl = match.courtImageUrl ?? court?.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: PulseColors.getCard(isDarkMode),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Court / Sport Header Banner
            SizedBox(
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.trim().isNotEmpty)
                    Image.network(
                      imageUrl.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(),
                    )
                  else
                    _buildFallbackBanner(),
                  // Scrim overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Floating Sport Badge & Distance Pill
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: PulseColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PulseSportIcons.getIcon(match.sport),
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    match.sportDisplayName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (distanceText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, size: 10, color: Colors.white70),
                                const SizedBox(width: 3),
                                Text(
                                  distanceText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Venue Name at bottom of banner
                  Positioned(
                    bottom: 6,
                    left: 10,
                    right: 10,
                    child: Text(
                      match.venueName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Card Body (Host info & Join action)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Host Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: PulseColors.getSurface(isDarkMode),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (host?.avatarUrl != null && host!.avatarUrl!.trim().isNotEmpty)
                        ? Image.network(
                            host.avatarUrl!.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildHostInitial(host.name),
                          )
                        : _buildHostInitial(host?.name ?? 'Host'),
                  ),
                  const SizedBox(width: 8),

                  // Host Name, Rating, and Scheduled Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          host?.name ?? 'Host Player',
                          style: TextStyle(
                            color: PulseColors.getTextPrimary(isDarkMode),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'ELO ${host?.rating ?? 1200}',
                                style: const TextStyle(
                                  color: PulseColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' • ${_formatTime(match.scheduledAt)}',
                                style: TextStyle(
                                  color: PulseColors.getTextSecondary(isDarkMode),
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Join Match Action Button
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: isJoining ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isJoining
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Join Match',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Icon(
            PulseSportIcons.getIcon(match.sport),
            size: 38,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildHostInitial(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'H';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: PulseColors.getTextPrimary(isDarkMode),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
