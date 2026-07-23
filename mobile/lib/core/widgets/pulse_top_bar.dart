import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';
import 'pulse_logo.dart';

/// Reusable Top Bar Component for Pulse App
///
/// Features Avatar on the left and Inbox/Notification icon on the right
/// using SpaceBetween layout alignment.
class PulseTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onInboxTap;

  const PulseTopBar({
    super.key,
    this.userName,
    this.avatarUrl,
    this.unreadCount = 0,
    this.onAvatarTap,
    this.onInboxTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72.0);

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.colorScheme.surface;
    final textPrimaryColor = theme.colorScheme.onSurface;
    final borderColor = isDark ? PulseColors.darkBorder : PulseColors.border;

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
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
            // Left: User Avatar
            GestureDetector(
              onTap: onAvatarTap,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: textPrimaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center: Large Pulse Logo
            const PulseLogo(size: 52.0),

            // Right: Inbox / Notification Icon
            GestureDetector(
              onTap: onInboxTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: textPrimaryColor,
                      size: 22,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: PulseColors.accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
