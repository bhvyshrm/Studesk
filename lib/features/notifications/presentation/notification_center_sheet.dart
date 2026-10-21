import 'package:flutter/material.dart';

import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';

class NotificationCenterSheet extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const NotificationCenterSheet({super.key, this.onNavigateToTab});

  static Future<void> show(
    BuildContext context, {
    void Function(int tabIndex)? onNavigateToTab,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) =>
          NotificationCenterSheet(onNavigateToTab: onNavigateToTab),
    );
  }

  @override
  State<NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final notifications = _repo.notifications.where((n) {
      if (n.isDismissed) {
        return false;
      }
      if (_selectedFilter == 'All') {
        return true;
      }
      if (_selectedFilter == 'Exams') {
        return n.type == NotificationType.exam;
      }
      if (_selectedFilter == 'Tasks') {
        return n.type == NotificationType.task;
      }
      if (_selectedFilter == 'Reminders') {
        return n.type == NotificationType.reminder;
      }
      return true;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: stuTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        if (_repo.unreadNotificationsCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: stuTheme.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_repo.unreadNotificationsCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: stuTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _repo.markAllNotificationsAsRead();
                          setState(() {});
                        },
                        child: Text(
                          'Mark all as read',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: stuTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: ['All', 'Exams', 'Tasks', 'Reminders'].map((
                    filter,
                  ) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: stuTheme.accent,
                        backgroundColor: stuTheme.surfaceTier2,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? stuTheme.onAccent
                              : stuTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : stuTheme.border,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // Content List or Empty State
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState(stuTheme)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationCard(notif, stuTheme);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(StuDeskThemeExtension stuTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 26,
                color: stuTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No new notices right now. Scheduled exams and due tasks will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: stuTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    InAppNotificationItem notif,
    StuDeskThemeExtension stuTheme,
  ) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case NotificationType.exam:
        icon = Icons.event_available_rounded;
        iconColor = stuTheme.error;
        break;
      case NotificationType.task:
        icon = Icons.assignment_late_rounded;
        iconColor = stuTheme.warning;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm_rounded;
        iconColor = stuTheme.accent;
        break;
      case NotificationType.timetable:
        icon = Icons.schedule_rounded;
        iconColor = stuTheme.success;
        break;
      case NotificationType.event:
        icon = Icons.calendar_month_rounded;
        iconColor = stuTheme.accent;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        iconColor = stuTheme.textSecondary;
        break;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: stuTheme.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: stuTheme.error),
      ),
      onDismissed: (_) {
        _repo.dismissNotification(notif.id);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _repo.markNotificationAsRead(notif.id);
          Navigator.pop(context);
          if (notif.type == NotificationType.exam ||
              notif.type == NotificationType.task) {
            widget.onNavigateToTab?.call(0); // Home
          } else if (notif.type == NotificationType.timetable) {
            widget.onNavigateToTab?.call(1); // Academics
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? stuTheme.surfaceTier1 : stuTheme.surfaceTier2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? stuTheme.border
                  : stuTheme.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: notif.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: stuTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: stuTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
