import 'package:flutter/material.dart';
import '../../main.dart';
import '../theme/pulse_colors.dart';

/// Reusable Ultra-Modern Widget Card Component for Pulse App
///
/// Features solid surface fill (default white in light mode),
/// top row with title, subtitle, and dark capsule pill badge,
/// and a centered graphic asset / content body.
class PulseWidgetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String pillText;
  final String? imagePath;
  final Widget? customContent;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? subtitleColor;
  final Color? pillBackgroundColor;
  final Color? pillTextColor;
  final VoidCallback onTap;
  final double? imageHeight;
  final bool? isDarkMode;

  const PulseWidgetCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pillText,
    this.imagePath,
    this.customContent,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.subtitleColor,
    this.pillBackgroundColor,
    this.pillTextColor,
    required this.onTap,
    this.imageHeight = 70.0,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode ??
        (themeModeNotifier.value == ThemeMode.dark ||
            Theme.of(context).brightness == Brightness.dark);

    final defaultSurface = PulseColors.getSurface(isDark);
    final surfaceColor = isDark
        ? PulseColors.darkSurface
        : (backgroundColor ?? defaultSurface);

    final textPrimary = textColor ??
        (isDark ? PulseColors.darkTextPrimary : const Color(0xFF1E293B));
    final textSecondary = subtitleColor ??
        (isDark ? PulseColors.darkTextSecondary : const Color(0xFF64748B));
    final effectiveBorder = borderColor ??
        (isDark ? PulseColors.darkBorder : Colors.black.withValues(alpha: 0.06));

    final pillBg = pillBackgroundColor ??
        (isDark ? PulseColors.darkCard : const Color(0xFF0F1718));
    final pillFg = pillTextColor ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: effectiveBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title, Subtitle + Sleek Dark Capsule Pill Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Capsule Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pillText,
                    style: TextStyle(
                      color: pillFg,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Content Area (Image asset or custom widget content)
            if (customContent != null)
              customContent!
            else if (imagePath != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Image.asset(
                      imagePath!,
                      height: imageHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.sports_tennis_rounded,
                          size: 48,
                          color: textSecondary,
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

