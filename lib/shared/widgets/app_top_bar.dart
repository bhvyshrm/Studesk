import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import 'pill_badge.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? titleTrailing;
  final List<Widget>? actions;
  final bool showProfile;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onNotificationsTap;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.actions,
    this.showProfile = true,
    this.onProfileTap,
    this.onCalendarTap,
    this.onNotificationsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  void _showProfileSheet(BuildContext context) {
    final stuTheme = context.stuTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: stuTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: stuTheme.border),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/studesk_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.school_rounded,
                            color: stuTheme.accent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Chen',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CS Year 2 • Roll #22CS1049',
                            style: TextStyle(
                              fontSize: 13,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PillBadge(
                      label: 'Sem 5',
                      backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
                      textColor: stuTheme.accent,
                      borderColor: stuTheme.accent.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: stuTheme.border, height: 1),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: stuTheme.accent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isDark ? 'AMOLED Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: stuTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    isDark ? 'Pure #000000 deep obsidian' : 'Modern Academic Elegance',
                    style: TextStyle(
                      color: stuTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeTrackColor: stuTheme.accent,
                    onChanged: (val) {
                      ThemeController.instance.toggleTheme();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: stuTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Academic Standing',
                    style: TextStyle(
                      color: stuTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Overall GPA: 3.82 • Top 10% in CSE',
                    style: TextStyle(
                      color: stuTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: stuTheme.textSecondary,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.stuTheme.surfaceTier3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.notifications_active_rounded,
                color: context.stuTheme.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Next: Data Structures starts in 20m in Hall B-204',
                style: TextStyle(
                  color: context.stuTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Container(
      color: stuTheme.canvas,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showProfile) ...[
            GestureDetector(
              onTap: onProfileTap ?? () => _showProfileSheet(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stuTheme.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/studesk_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.school_rounded,
                          color: stuTheme.accent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: stuTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: stuTheme.canvas, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: stuTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null)
            ...actions!
          else ...[
            // Quick Theme Toggle Button
            IconButton(
              tooltip: 'Toggle Theme',
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                size: 20,
                color: stuTheme.textSecondary,
              ),
              onPressed: () => ThemeController.instance.toggleTheme(),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
            ),
            // Calendar action
            IconButton(
              tooltip: 'Schedule Calendar',
              icon: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: stuTheme.textSecondary,
              ),
              onPressed: onCalendarTap ?? () {},
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
            ),
            // Notification action with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: stuTheme.textSecondary,
                  ),
                  onPressed: onNotificationsTap ?? () => _showNotificationNotice(context),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: stuTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: stuTheme.canvas, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
