import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../auth/models/user_model.dart';
import '../../../matches/models/match_model.dart';
import '../../services/notification_service.dart';
import 'notification_card_tile.dart';

/// Dedicated Notification Side Drawer Widget Component
class NotificationSideDrawer extends StatefulWidget {
  final bool isDarkMode;
  final UserModel? user;
  final MatchModel? activeMatch;
  final bool isInvitationPending;
  final List<MatchModel> historyMatches;
  final VoidCallback onAcceptMatchInvitation;
  final VoidCallback onDeclineMatchInvitation;

  const NotificationSideDrawer({
    super.key,
    required this.isDarkMode,
    required this.user,
    required this.activeMatch,
    required this.isInvitationPending,
    required this.historyMatches,
    required this.onAcceptMatchInvitation,
    required this.onDeclineMatchInvitation,
  });

  @override
  State<NotificationSideDrawer> createState() => _NotificationSideDrawerState();
}

class _NotificationSideDrawerState extends State<NotificationSideDrawer> {
  final NotificationService _notificationService = NotificationService();
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didUpdateWidget(covariant NotificationSideDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.id != widget.user?.id ||
        oldWidget.historyMatches.length != widget.historyMatches.length ||
        oldWidget.isInvitationPending != widget.isInvitationPending) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    await _notificationService.fetchBackendNotifications(
      user: widget.user,
      historyMatches: widget.historyMatches,
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = PulseColors.getTextPrimary(widget.isDarkMode);
    final isDark = widget.isDarkMode;
    final notifications = _notificationService.getNotifications(
      unreadOnly: _filter == 'UNREAD',
    );

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      backgroundColor: PulseColors.getBackground(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header (Back Arrow + Title)
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 12.0, 16.0, 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PulseBackButton(isDarkMode: widget.isDarkMode),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 2. All / Unread Tabs & Mark All as Read
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTabItem('All', selected: _filter == 'ALL', onTap: () {
                    setState(() => _filter = 'ALL');
                  }),
                  const SizedBox(width: 20),
                  _buildTabItem('Unread', selected: _filter == 'UNREAD', onTap: () {
                    setState(() => _filter = 'UNREAD');
                  }),
                  const Spacer(),
                  if (notifications.any((n) => n.isUnread))
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await _notificationService.markAllAsRead();
                          if (!mounted) return;
                          setState(() {});
                          if (context.mounted) {
                            PulseToast.show(context, 'All notifications marked as read');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Mark all as read',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: PulseColors.accent,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: PulseColors.getBorder(isDark)),

            // 3. Main List Feed
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                children: [
                  // High Priority Invitation Card (if active and not filtering out)
                  if (widget.isInvitationPending && widget.activeMatch != null) ...[
                    _buildInviteCard(context),
                    const SizedBox(height: 14),
                  ],

                  if (notifications.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      child: Center(
                        child: Text(
                          'No unread notifications',
                          style: TextStyle(
                            fontSize: 13,
                            color: PulseColors.getTextSecondary(isDark),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    for (int i = 0; i < notifications.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      NotificationCardTile(
                        item: notifications[i],
                        isDarkMode: isDark,
                        onMarkAsRead: () async {
                          await _notificationService.markAsRead(notifications[i].id);
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? PulseColors.getTextPrimary(widget.isDarkMode)
                  : PulseColors.getTextSecondary(widget.isDarkMode),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: selected ? 28 : 0,
            decoration: BoxDecoration(
              color: selected ? PulseColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context) {
    final inviterName = widget.activeMatch?.player1?.name ?? 'Match Host';
    final sport = widget.activeMatch?.sportDisplayName ?? 'Pickleball';
    final venue = widget.activeMatch?.venueName ?? 'Court #1';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: PulseColors.getSurface(widget.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PulseColors.accent.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INVITE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: PulseColors.accent,
                  letterSpacing: 0.6,
                ),
              ),
              const Icon(Icons.flash_on_rounded, color: PulseColors.accent, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$inviterName invited you to a $sport match at $venue.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PulseColors.getTextPrimary(widget.isDarkMode),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDeclineMatchInvitation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.error.withValues(alpha: 0.12),
                    foregroundColor: PulseColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    widget.onAcceptMatchInvitation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Accept & Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
