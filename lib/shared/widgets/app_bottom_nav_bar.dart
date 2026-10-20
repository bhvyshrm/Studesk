import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Clean 4-destination bottom navigation bar with icons only (no visible text labels),
/// complete screen-reader accessibility semantics, tooltips, and responsive layout.
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
    final navBarHeight = 60.0 + (bottomInset > 0 ? bottomInset : 6.0);

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: isDark ? stuTheme.canvas : stuTheme.surfaceTier1,
        border: Border(
          top: BorderSide(color: stuTheme.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            offset: const Offset(0, -3),
            blurRadius: 16,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 6,
        bottom: bottomInset > 0 ? bottomInset : 6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(
                context: context,
                index: 0,
                icon: Icons.home_rounded,
                selectedIcon: Icons.home_rounded,
                semanticLabel: 'Home',
                tooltip: 'Home Dashboard',
              ),
              _buildNavIcon(
                context: context,
                index: 1,
                icon: Icons.school_outlined,
                selectedIcon: Icons.school_rounded,
                semanticLabel: 'Academics',
                tooltip: 'Syllabus, Notes & Timetable',
              ),
              _buildNavIcon(
                context: context,
                index: 2,
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                semanticLabel: 'Library',
                tooltip: 'Personal Learning Collections & Resources',
              ),
              _buildNavIcon(
                context: context,
                index: 3,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                semanticLabel: 'Profile',
                tooltip: 'Profile, Attendance & Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon({
    required BuildContext context,
    required int index,
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
        child: InkResponse(
          onTap: () => onDestinationSelected(index),
          radius: 28,
          containedInkWell: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? stuTheme.accent.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected ? stuTheme.accent : stuTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
