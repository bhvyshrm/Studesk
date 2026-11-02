import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Floating, iOS-inspired rounded bottom navigation bar for StuDesk.
///
/// Features:
/// - Visually separated from bottom and side screen edges (floating island)
/// - Rounded pill container (28px radius)
/// - Restrained elevation and subtle monochrome border
/// - Safe area inset awareness for modern gesture navigation
/// - Centered horizontal layout with max-width constraints for tablets
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
    final bottomMargin = bottomInset > 0 ? bottomInset : 10.0;
    final totalNavHeight = 60.0 + bottomMargin + 6.0;

    return SizedBox(
      height: totalNavHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 4.0,
          bottom: bottomMargin,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              height: 56.0,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101010) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: stuTheme.border, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? stuTheme.surfaceTier2 : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.md),
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
                  size: 20,
                  color: isSelected ? stuTheme.textPrimary : stuTheme.textMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
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
