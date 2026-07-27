import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

import 'rally_text_logo.dart';

/// Reusable Top Bar Component for Pulse App
///
/// Features Avatar on the left, central RALLY brand logo, and Inbox notification icon on the right.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerBgGradient = LinearGradient(
      colors: isDark
          ? [PulseColors.darkSurface, const Color(0xFF121B1C)]
          : [PulseColors.primary, const Color(0xFF1E3C42)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final iconBgColor = isDark ? PulseColors.darkCard : Colors.white.withValues(alpha: 0.15);
    final borderColor = isDark ? PulseColors.darkBorder : PulseColors.secondary.withValues(alpha: 0.3);

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: headerBgGradient,
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
                    color: isDark ? PulseColors.secondary : Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
                        color: isDark ? PulseColors.darkBorder : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
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
                          border: Border.all(color: Colors.white, width: 1.5),
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
