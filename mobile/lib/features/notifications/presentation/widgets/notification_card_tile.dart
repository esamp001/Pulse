import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../auth/services/auth_service.dart';
import '../../../matches/presentation/screens/post_match_screen.dart';
import '../../../matches/services/match_service.dart';
import '../../domain/models/notification_item_model.dart';

/// Reusable Notification Card Tile Widget
class NotificationCardTile extends StatelessWidget {
  final NotificationItemModel item;
  final bool isDarkMode;
  final VoidCallback onMarkAsRead;

  const NotificationCardTile({
    super.key,
    required this.item,
    required this.isDarkMode,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = PulseColors.getSurface(isDarkMode);
    final textPrimary = PulseColors.getTextPrimary(isDarkMode);
    final textSecondary = PulseColors.getTextSecondary(isDarkMode);

    return GestureDetector(
      onTap: () async {
        if (item.isUnread) onMarkAsRead();
        final matchId = item.payload?['matchId'] ?? item.payload?['match_id'];
        if (matchId != null) {
          try {
            final match = await MatchService().getMatchById(matchId.toString());
            if (context.mounted) {
              final userId = AuthService.currentUser?.id ?? '';
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PostMatchScreen(
                    match: match,
                    currentUserId: userId,
                  ),
                ),
              );
            }
          } catch (_) {}
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: null,
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell Icon (matching user screenshot requirement)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PulseColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: PulseColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Label (plain text, NO background color pill)
                          Text(
                            item.category.tagLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: PulseColors.accent,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.dateText,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Subtitle Body
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
                // Action: Mark as read if unread
                if (item.isUnread) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        onMarkAsRead();
                        PulseToast.show(context, 'Notification marked as read');
                      },
                      child: const Text(
                        'Mark as read',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PulseColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
