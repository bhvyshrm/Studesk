import 'package:flutter/material.dart';

import '../../core/data/studesk_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/notifications/presentation/notification_center_sheet.dart';
import '../../features/search/presentation/global_search_sheet.dart';
import 'studesk_wordmark.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final List<Widget>? actions;
  final bool showBrandWordmark;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSearchTap;
  final void Function(int tabIndex)? onNavigateToTab;

  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.actions,
    this.showBrandWordmark = true,
    this.onNotificationsTap,
    this.onSearchTap,
    this.onNavigateToTab,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final repo = StuDeskRepository.instance;

    return Container(
      color: stuTheme.canvas,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 20,
        right: 12,
        bottom: 8,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top-left: StuDesk Wordmark or title
              if (showBrandWordmark)
                const StuDeskWordmark(fontSize: 24, showDot: true)
              else if (title != null)
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
                              title!,
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

              const Spacer(),

              // Global Actions
              if (actions != null)
                ...actions!
              else ...[
                // Search entry point
                IconButton(
                  tooltip: 'Search Desk',
                  icon: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: stuTheme.textSecondary,
                  ),
                  onPressed:
                      onSearchTap ??
                      () => GlobalSearchSheet.show(
                        context,
                        onNavigateToTab: onNavigateToTab,
                      ),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),

                // Theme Toggle
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

                // Top-right: Notification bell with real unread badge
                ListenableBuilder(
                  listenable: repo,
                  builder: (context, _) {
                    final unread = repo.unreadNotificationsCount;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'In-App Notifications',
                          icon: Icon(
                            unread > 0
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            size: 22,
                            color: unread > 0
                                ? stuTheme.accent
                                : stuTheme.textSecondary,
                          ),
                          onPressed:
                              onNotificationsTap ??
                              () => NotificationCenterSheet.show(
                                context,
                                onNavigateToTab: onNavigateToTab,
                              ),
                          style: IconButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: stuTheme.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: stuTheme.canvas,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
