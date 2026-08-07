import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';

class SportOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageAsset;

  const SportOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageAsset,
  });
}

class SportSelectorCard extends StatelessWidget {
  final SportOption option;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const SportSelectorCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? (isDarkMode
            ? PulseColors.primary.withValues(alpha: 0.3)
            : PulseColors.secondary.withValues(alpha: 0.25))
        : PulseColors.getCard(isDarkMode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          // STRICT NO FORCED BORDER RULE & BORDERLESS DESIGN
        ),
        child: Row(
          children: [
            // Modern Larger Borderless Gradient Icon Container
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [PulseColors.accent, PulseColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: isDarkMode
                            ? [
                                PulseColors.accent.withValues(alpha: 0.2),
                                PulseColors.primary.withValues(alpha: 0.15),
                              ]
                            : [
                                PulseColors.secondary.withValues(alpha: 0.35),
                                PulseColors.background,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Center(
                child: option.imageAsset != null
                    ? Image.asset(
                        option.imageAsset!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          option.icon,
                          size: 40,
                          color: isSelected
                              ? Colors.white
                              : PulseColors.getTextPrimary(isDarkMode),
                        ),
                      )
                    : Icon(
                        option.icon,
                        size: 40,
                        color: isSelected
                            ? Colors.white
                            : PulseColors.getTextPrimary(isDarkMode),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PulseColors.getTextPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: PulseColors.getTextSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: PulseColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
