import 'package:flutter/material.dart';
import '../../main.dart';
import '../theme/pulse_colors.dart';

/// Reusable Ultra-Modern Widget Card Component for Pulse App
///
/// Features solid surface fill, dynamic text scaleDown protection,
/// top row with title, subtitle, and dark capsule pill badge,
/// and optional Netflix-style gradient black "COMING SOON" overlay.
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
  final bool isComingSoon;

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
    this.isComingSoon = false,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 160;
          final cardPadding = isCompact ? 12.0 : 14.0;
          final titleFontSize = isCompact ? 14.0 : 15.0;
          final subtitleFontSize = isCompact ? 10.5 : 11.0;
          final pillPadding = isCompact
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

          return Stack(
            children: [
              Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: isComingSoon ? const Color(0xFF12191A) : surfaceColor,
                  gradient: isComingSoon
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1A2325),
                            Color(0xFF0A0F10),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isComingSoon
                        ? Colors.white.withValues(alpha: 0.15)
                        : effectiveBorder,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: Title, Subtitle + Sleek Capsule Pill Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: isComingSoon ? Colors.white : textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: isComingSoon
                                        ? Colors.white.withValues(alpha: 0.65)
                                        : textSecondary,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Capsule Pill Badge
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: pillPadding,
                              decoration: BoxDecoration(
                                color: isComingSoon
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : pillBg,
                                borderRadius: BorderRadius.circular(12),
                                border: isComingSoon
                                    ? Border.all(
                                        color: Colors.white.withValues(alpha: 0.2))
                                    : null,
                              ),
                              child: Text(
                                pillText,
                                style: TextStyle(
                                  color: isComingSoon
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : pillFg,
                                  fontSize: isCompact ? 9 : 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
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
                            child: Opacity(
                              opacity: isComingSoon ? 0.30 : 1.0,
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
                      ),
                  ],
                ),
              ),

              // Netflix-Style Centered "COMING SOON" Pill Badge Overlay
              if (isComingSoon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        margin: const EdgeInsets.only(top: 22),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1718).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PulseColors.accent.withValues(alpha: 0.7),
                            width: 1.0,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_clock_rounded,
                                size: 11,
                                color: PulseColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'COMING SOON',
                                style: TextStyle(
                                  fontSize: isCompact ? 9 : 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
