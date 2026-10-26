import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Restrained, modern 4-destination bottom navigation bar with monochrome icons,
/// elegant typography labels, accessible touch targets (48dp+), screen-reader semantics,
/// and safe-area padding for mobile devices.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 64.0 + (bottomInset > 0 ? bottomInset : 8.0);

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: isDark ? stuTheme.canvas : stuTheme.surfaceTier1,
        border: Border(top: BorderSide(color: stuTheme.border, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.04),
            offset: const Offset(0, -3),
            blurRadius: 16,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 6,
        bottom: bottomInset > 0 ? bottomInset : 6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  semanticLabel: 'Home',
                  tooltip: 'Home Dashboard',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 1,
                  label: 'Academics',
                  icon: Icons.school_outlined,
                  selectedIcon: Icons.school_rounded,
                  semanticLabel: 'Academics',
                  tooltip: 'Syllabus, Notes & Timetable',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 2,
                  label: 'Library',
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  semanticLabel: 'Library',
                  tooltip: 'Personal Learning Collections & Resources',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 3,
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  semanticLabel: 'Profile',
                  tooltip: 'Profile, Attendance & Settings',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required String semanticLabel,
    required String tooltip,
  }) {
    final isSelected = currentIndex == index;
    final stuTheme = context.stuTheme;

    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? stuTheme.surfaceTier2
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: stuTheme.border, width: 0.8)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 21,
                  color: isSelected
                      ? stuTheme.textPrimary
                      : stuTheme.textMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.1,
                    color: isSelected
                        ? stuTheme.textPrimary
                        : stuTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
