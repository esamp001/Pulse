import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

/// Standard Circular Back Button for Pulse App with background fill
class PulseBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDarkMode;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const PulseBackButton({
    super.key,
    this.onPressed,
    required this.isDarkMode,
    this.backgroundColor,
    this.iconColor,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (isDarkMode
            ? PulseColors.darkCard
            : const Color(0xFFE5EFF2));
    final fg = iconColor ?? PulseColors.getTextPrimary(isDarkMode);

    return Tooltip(
      message: 'Back',
      child: InkWell(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: fg,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
