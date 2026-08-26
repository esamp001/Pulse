import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';

enum SignalConnectionStatus {
  online,
  offline,
  reconnecting,
  reconnected,
}

/// Minimalist Signal Recovery Banner for Court Live Scoring & Match Lobby
class SignalRecoveryBanner extends StatelessWidget {
  final SignalConnectionStatus status;
  final int pendingQueueCount;
  final bool isDarkMode;
  final VoidCallback? onRetry;

  const SignalRecoveryBanner({
    super.key,
    required this.status,
    this.pendingQueueCount = 0,
    required this.isDarkMode,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == SignalConnectionStatus.online) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color dotColor;
    Color textColor;
    String statusTitle;
    String statusSubtitle;

    switch (status) {
      case SignalConnectionStatus.offline:
        bgColor = const Color(0xFFF59E0B).withValues(alpha: isDarkMode ? 0.18 : 0.12);
        dotColor = const Color(0xFFF59E0B);
        textColor = isDarkMode ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
        statusTitle = 'OFFLINE';
        statusSubtitle = pendingQueueCount > 0
            ? 'Scores saved locally ($pendingQueueCount pending sync)'
            : 'Scores saved locally • Auto-syncing on reconnect';
        break;

      case SignalConnectionStatus.reconnecting:
        bgColor = PulseColors.primary.withValues(alpha: isDarkMode ? 0.22 : 0.12);
        dotColor = const Color(0xFF3B82F6);
        textColor = isDarkMode ? const Color(0xFF93C5FD) : PulseColors.primary;
        statusTitle = 'RECONNECTING';
        statusSubtitle = 'Syncing with court room...';
        break;

      case SignalConnectionStatus.reconnected:
        bgColor = const Color(0xFF22C55E).withValues(alpha: isDarkMode ? 0.20 : 0.12);
        dotColor = const Color(0xFF22C55E);
        textColor = isDarkMode ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
        statusTitle = 'BACK ONLINE';
        statusSubtitle = 'All match points synchronized with court';
        break;

      case SignalConnectionStatus.online:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Minimal Colored Status Dot Indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusSubtitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (status == SignalConnectionStatus.offline && onRetry != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
