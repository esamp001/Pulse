import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

/// Reusable Floating Capsule Bottom Navigation Dock for Pulse App
class PulseBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PulseBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dockBgColor = isDark ? const Color(0xFF141E20) : const Color(0xFF1A2B2E);
    final borderColor = isDark ? const Color(0xFF2E4549) : const Color(0xFF2C4347);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dockBgColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFloatingNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  const SizedBox(width: 6),
                  _buildFloatingNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history_rounded,
                    label: 'History',
                  ),
                  const SizedBox(width: 6),
                  _buildCenterCompeteNavItem(
                    context: context,
                    index: 2,
                  ),
                  const SizedBox(width: 6),
                  _buildFloatingNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.leaderboard_outlined,
                    activeIcon: Icons.leaderboard_rounded,
                    label: 'Rankings',
                  ),
                  const SizedBox(width: 6),
                  _buildFloatingNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCompeteNavItem({
    required BuildContext context,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : PulseColors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.bolt_rounded,
            color: isSelected ? PulseColors.accent : Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFF142225) : Colors.white.withValues(alpha: 0.7),
            size: isSelected ? 22 : 23,
          ),
        ),
      ),
    );
  }
}
