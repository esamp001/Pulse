import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';

/// Modern Native Bottom Navigation Bar for Pulse App with Popped Compete Button
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
    final navBgColor = isDark ? PulseColors.darkSurface : Colors.white;

    return Container(
      color: navBgColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.grid_view_rounded,
                    inactiveIcon: Icons.grid_view_outlined,
                    label: 'Home',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.auto_graph_rounded,
                    inactiveIcon: Icons.auto_graph_rounded,
                    label: 'History',
                    isDark: isDark,
                  ),
                  _buildCenterCompeteItem(
                    context: context,
                    index: 2,
                    isDark: isDark,
                    navBgColor: navBgColor,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.emoji_events_rounded,
                    inactiveIcon: Icons.emoji_events_outlined,
                    label: 'Rankings',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.account_circle_rounded,
                    inactiveIcon: Icons.account_circle_outlined,
                    label: 'Profile',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCompeteItem({
    required BuildContext context,
    required int index,
    required bool isDark,
    required Color navBgColor,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = PulseColors.accent;
    final inactiveColor = PulseColors.getTextSecondary(isDark);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: OverflowBox(
          maxHeight: 76,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Transform.translate(
                offset: const Offset(0, -6),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : PulseColors.getCard(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: navBgColor,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.stadium_rounded,
                      color: isSelected ? Colors.white : activeColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Compete',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = isDark ? PulseColors.accent : PulseColors.primary;
    final inactiveColor = PulseColors.getTextSecondary(isDark);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? icon : inactiveIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





