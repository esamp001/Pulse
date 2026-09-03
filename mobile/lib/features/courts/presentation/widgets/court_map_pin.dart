import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../models/court_model.dart';

/// Reusable circular map pin marker for courts.
/// Displays the court photo if available, with automatic fallback
/// to the primary sport icon.
class CourtMapPin extends StatelessWidget {
  final CourtModel court;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;
  final bool? isDarkMode;

  const CourtMapPin({
    super.key,
    required this.court,
    this.isSelected = false,
    this.size = 42.0,
    this.onTap,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);
    final hasImage = court.imageUrl != null && court.imageUrl!.trim().isNotEmpty;
    final borderColor = isSelected ? PulseColors.primary : Colors.white;
    final borderWidth = isSelected ? 3.0 : 2.0;

    final pinWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : PulseColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                court.imageUrl!.trim(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackContent(isDark),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallbackContent(isDark);
                },
              )
            : _buildFallbackContent(isDark),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: pinWidget,
      );
    }

    return pinWidget;
  }

  Widget _buildFallbackContent(bool isDark) {
    return Container(
      color: isSelected ? Colors.white : PulseColors.primary,
      alignment: Alignment.center,
      child: Icon(
        PulseSportIcons.getIcon(court.primarySport.toLowerCase()),
        size: size * 0.45,
        color: isSelected ? PulseColors.primary : Colors.white,
      ),
    );
  }
}
