import 'package:flutter/material.dart';
import '../../main.dart';
import '../theme/pulse_colors.dart';
import 'rally_text_logo.dart';

/// Reusable Top Bar Component for Pulse App
///
/// Features Avatar on the left, central RALLY brand logo, and Inbox notification icon on the right.
class PulseTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String? avatarUrl;
  final int unreadCount;
  final bool? isDarkMode;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onInboxTap;

  const PulseTopBar({
    super.key,
    this.userName,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isDarkMode,
    this.onAvatarTap,
    this.onInboxTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = userName != null ? _getInitials(userName!) : 'E';
    final isDark = isDarkMode ??
        (themeModeNotifier.value == ThemeMode.dark ||
            Theme.of(context).brightness == Brightness.dark);

    final headerBgColor = PulseColors.getSurface(isDark);
    final iconBgColor = isDark ? PulseColors.darkCard : PulseColors.background;
    final borderColor = PulseColors.getBorder(isDark);
    final iconColor = isDark ? Colors.white : PulseColors.primary;
    final avatarTextColor = isDark ? Colors.white : PulseColors.primary;

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: headerBgColor,
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: User Avatar Button
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? PulseColors.accent : PulseColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: avatarTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: avatarTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Center: Brand Logo
            const RallyTextLogo(
              fontSize: 20.0,
              showSubtitle: false,
            ),

            // Right: Inbox / Notification Icon Button
            GestureDetector(
              onTap: onInboxTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: PulseColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: headerBgColor, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
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
}

