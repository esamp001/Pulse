import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../models/match_model.dart';

class MatchRadarPin extends StatelessWidget {
  final MatchModel match;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const MatchRadarPin({
    super.key,
    required this.match,
    this.isSelected = false,
    this.size = 46.0,
    this.onTap,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final host = match.player1;
    final avatarUrl = host?.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isSelected ? size + 10 : size,
          height: isSelected ? size + 10 : size,
          padding: EdgeInsets.all(isSelected ? 3.0 : 2.0),
          decoration: BoxDecoration(
            color: isSelected ? PulseColors.primary : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
            shape: BoxShape.circle,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasAvatar)
                    Image.network(
                      avatarUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackContent(),
                    )
                  else
                    _buildFallbackContent(),
                  // Sport mini badge in corner
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: PulseColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PulseSportIcons.getIcon(match.sport),
                        size: 9,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackContent() {
    final host = match.player1;
    if (host != null && host.name.isNotEmpty) {
      return Center(
        child: Text(
          host.initials,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: isSelected ? 14 : 12,
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        PulseSportIcons.getIcon(match.sport),
        size: isSelected ? 20 : 16,
        color: PulseColors.primary,
      ),
    );
  }
}
