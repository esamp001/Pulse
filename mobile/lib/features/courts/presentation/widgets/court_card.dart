import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../models/court_model.dart';
import '../screens/court_route_screen.dart';
import 'court_reviews_sheet.dart';

class CourtCard extends StatelessWidget {
  final CourtModel court;
  final bool isDarkMode;
  final VoidCallback onHostMatch;
  final ValueChanged<CourtModel>? onCourtUpdated;

  const CourtCard({
    super.key,
    required this.court,
    required this.isDarkMode,
    required this.onHostMatch,
    this.onCourtUpdated,
  });

  void _openInAppDirections(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CourtRouteScreen(court: court)));
  }

  void _openReviewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourtReviewsSheet(
        court: court,
        isDarkMode: isDarkMode,
        onCourtUpdated: onCourtUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = court.formattedDistance;
    final hasImage = court.imageUrl != null && court.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: PulseColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        // Strict rule: NO drop shadows or forced styling borders
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Netflix-style full-bleed image with black gradient overlay
          if (hasImage)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    court.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: isDarkMode
                          ? PulseColors.darkSurface
                          : Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          PulseSportIcons.getIcon(
                            court.primarySport.toLowerCase(),
                          ),
                          size: 36,
                          color: isDarkMode
                              ? Colors.white30
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  // Netflix-style Natural Easing Black Gradient (smooth bottom falloff)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.26),
                          Colors.black.withValues(alpha: 0.48),
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.90),
                        ],
                        stops: const [
                          0.0,
                          0.45,
                          0.60,
                          0.72,
                          0.82,
                          0.90,
                          0.96,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                  // Floating distance badge in top-right corner
                  if (distanceText.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 11,
                              color: PulseColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, hasImage ? 14 : 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Name & Distance Tag (shown here if card has no image)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court.name,
                            style: TextStyle(
                              color: PulseColors.getTextPrimary(isDarkMode),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (court.address != null &&
                              court.address!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              court.address!,
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDarkMode),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!hasImage && distanceText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? PulseColors.secondary.withValues(alpha: 0.15)
                              : PulseColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          distanceText,
                          style: TextStyle(
                            color: isDarkMode
                                ? PulseColors.secondary
                                : PulseColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Sports & Amenity tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Sports tags
                    ...court.sports.map((sport) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.getSurface(isDarkMode),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PulseSportIcons.getIcon(sport),
                              size: 11,
                              color: isDarkMode
                                  ? Colors.white
                                  : PulseColors.getTextSecondary(isDarkMode),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sport[0].toUpperCase() + sport.substring(1),
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDarkMode),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Lighting tag
                    if (court.hasLighting)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.getSurface(isDarkMode),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 11,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Night Lights',
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDarkMode),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Indoor tag
                    if (court.isIndoor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.getSurface(isDarkMode),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.roofing_rounded,
                              size: 11,
                              color: isDarkMode
                                  ? Colors.white
                                  : PulseColors.getTextSecondary(isDarkMode),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Indoor',
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDarkMode),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Community Rating & Review Chip
                    GestureDetector(
                      onTap: () => _openReviewsSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              court.totalVotes > 0 &&
                                  court.recommendationPercent >= 70
                              ? (isDarkMode
                                    ? PulseColors.secondary.withValues(
                                        alpha: 0.15,
                                      )
                                    : PulseColors.primary.withValues(
                                        alpha: 0.12,
                                      ))
                              : PulseColors.getSurface(isDarkMode),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              court.totalVotes > 0
                                  ? Icons.thumb_up_rounded
                                  : Icons.rate_review_outlined,
                              size: 11,
                              color: isDarkMode
                                  ? Colors.white
                                  : (court.totalVotes > 0 &&
                                            court.recommendationPercent >= 70
                                        ? PulseColors.primary
                                        : PulseColors.getTextSecondary(
                                            isDarkMode,
                                          )),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              court.totalVotes > 0
                                  ? '${court.recommendationPercent}% (${court.totalVotes})'
                                  : 'Tips & Reviews',
                              style: TextStyle(
                                color:
                                    court.totalVotes > 0 &&
                                        court.recommendationPercent >= 70
                                    ? (isDarkMode
                                          ? PulseColors.secondary
                                          : PulseColors.primary)
                                    : PulseColors.getTextSecondary(isDarkMode),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons: Directions & Host Match
                Row(
                  children: [
                    // Directions button (Minimalist borderless surface button)
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => _openInAppDirections(context),
                          icon: Icon(
                            Icons.directions_rounded,
                            size: 15,
                            color: isDarkMode
                                ? Colors.white
                                : PulseColors.primary,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Directions',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : PulseColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: isDarkMode
                                ? Colors.white.withValues(alpha: 0.10)
                                : PulseColors.primary.withValues(alpha: 0.08),
                            foregroundColor: isDarkMode
                                ? Colors.white
                                : PulseColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Host Here button
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: onHostMatch,
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Host Here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0, // Strict rule: No drop shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
