import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';

class SportOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const SportOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
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
    final borderColor = isSelected
        ? PulseColors.accent
        : (isDarkMode ? PulseColors.darkBorder : PulseColors.border);

    final backgroundColor = isSelected
        ? (isDarkMode
            ? PulseColors.primary.withValues(alpha: 0.25)
            : PulseColors.secondary.withValues(alpha: 0.2))
        : PulseColors.getCard(isDarkMode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          // STRICT NO DROP SHADOW RULE
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? PulseColors.accent
                    : (isDarkMode ? PulseColors.darkSurface : PulseColors.background),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? PulseColors.accent : PulseColors.getBorder(isDarkMode),
                  width: 1,
                ),
              ),
              child: Icon(
                option.icon,
                size: 24,
                color: isSelected
                    ? Colors.white
                    : PulseColors.getTextPrimary(isDarkMode),
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
                padding: const EdgeInsets.all(4),
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
