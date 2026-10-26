import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/dialogs/studesk_forms.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/custom_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToAcademics;
  final VoidCallback onNavigateToLibrary;
  final VoidCallback onNavigateToProfile;

  const HomeScreen({
    super.key,
    required this.onNavigateToAcademics,
    required this.onNavigateToLibrary,
    required this.onNavigateToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StuDeskRepository _repo = StuDeskRepository.instance;

  static const List<String> _motivationalPhrases = [
    'One focused session changes the entire day.',
    'Small academic habits compound into mastery.',
    'Stay curious and take it one concept at a time.',
    'Clear desk, clear mind, steady progress.',
  ];

  String _getMotivationalPhrase() {
    final dayOfYear = int.tryParse(DateFormat('D').format(DateTime.now())) ?? 0;
    return _motivationalPhrases[dayOfYear % _motivationalPhrases.length];
  }

  void _showAddPlanItemSheet() {
    final stuTheme = context.stuTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              Text(
                'Add to Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildAddTile(
                icon: Icons.check_circle_outline_rounded,
                title: 'New Task',
                subtitle: 'Assignment or study task with due date',
                onTap: () {
                  Navigator.pop(ctx);
                  StuDeskForms.showTaskForm(context);
                },
              ),
              _buildAddTile(
                icon: Icons.calendar_today_rounded,
                title: 'New Event',
                subtitle: 'Campus meeting, workshop, or event',
                onTap: () {
                  Navigator.pop(ctx);
                  StuDeskForms.showEventForm(context);
                },
              ),
              _buildAddTile(
                icon: Icons.event_available_rounded,
                title: 'Upcoming Exam',
                subtitle: 'Midterm, quiz, or final exam date',
                onTap: () {
                  Navigator.pop(ctx);
                  StuDeskForms.showExamForm(context);
                },
              ),
              _buildAddTile(
                icon: Icons.alarm_rounded,
                title: 'Quick Reminder',
                subtitle: 'Reminder for submission or preparation',
                onTap: () {
                  Navigator.pop(ctx);
                  StuDeskForms.showReminderForm(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final stuTheme = context.stuTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stuTheme.border),
        ),
        child: Icon(icon, color: stuTheme.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: stuTheme.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: stuTheme.textSecondary, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: stuTheme.textSecondary,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final profile = _repo.profile;
        final displayName = profile.effectiveDisplayName;

        // Today's aggregated records
        final todayClasses = _repo.todayClasses;
        final todayTasks = _repo.todayTasks;
        final todayExams = _repo.todayExams;
        final todayEvents = _repo.todayEvents;
        final todayReminders = _repo.todayReminders;

        final pendingTasksCount = todayTasks.where((t) => !t.isCompleted).length;

        final hasTodayItems =
            todayClasses.isNotEmpty ||
            todayTasks.isNotEmpty ||
            todayExams.isNotEmpty ||
            todayEvents.isNotEmpty ||
            todayReminders.isNotEmpty;

        // Nearest upcoming items
        final upcomingExams = _repo.exams
            .where((e) => e.examDate.isAfter(DateTime.now()))
            .toList();
        final upcomingTasks = _repo.tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isAfter(DateTime.now()),
            )
            .toList();
        final upcomingEvents = _repo.events
            .where((e) => e.eventDate.isAfter(DateTime.now()))
            .toList();

        final hasUpcomingItems =
            upcomingExams.isNotEmpty ||
            upcomingTasks.isNotEmpty ||
            upcomingEvents.isNotEmpty;

        final formattedDate = DateFormat('EEEE, MMM d')
            .format(DateTime.now())
            .toUpperCase();

        final initials = displayName.isNotEmpty
            ? displayName.substring(0, 1).toUpperCase()
            : 'S';

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppTopBar(
            showBrandWordmark: true,
            onNavigateToTab: (index) {
              if (index == 1) widget.onNavigateToAcademics();
              if (index == 2) widget.onNavigateToLibrary();
              if (index == 3) widget.onNavigateToProfile();
            },
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 5.1: Contextual Date
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Section 5.2: Header with Greeting & Avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good day, $displayName',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: stuTheme.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.course.isNotEmpty
                                      ? '${profile.course}${profile.college.isNotEmpty ? ' • ${profile.college}' : ''}'
                                      : _getMotivationalPhrase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: stuTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: 'View Profile',
                            child: InkWell(
                              onTap: widget.onNavigateToProfile,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: stuTheme.surfaceTier2,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: stuTheme.border,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: stuTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Section 5.3: Today's Overview Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Classes Today',
                              count: todayClasses.length,
                              icon: Icons.schedule_rounded,
                              stuTheme: stuTheme,
                              onTap: widget.onNavigateToAcademics,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Pending Tasks',
                              count: pendingTasksCount,
                              icon: Icons.check_circle_outline_rounded,
                              stuTheme: stuTheme,
                              onTap: _showAddPlanItemSheet,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Radar Exams',
                              count: upcomingExams.length,
                              icon: Icons.event_available_rounded,
                              stuTheme: stuTheme,
                              onTap: () => StuDeskForms.showExamForm(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Section 5.4: Shortcuts Bar
                      Text(
                        'Shortcuts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickActionButton(
                              icon: Icons.add_task_rounded,
                              label: '+ Task',
                              stuTheme: stuTheme,
                              onTap: () => StuDeskForms.showTaskForm(context),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickActionButton(
                              icon: Icons.school_outlined,
                              label: '+ Subject',
                              stuTheme: stuTheme,
                              onTap: () => StuDeskForms.showSubjectForm(context),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickActionButton(
                              icon: Icons.description_outlined,
                              label: '+ Note',
                              stuTheme: stuTheme,
                              onTap: () => StuDeskForms.showNoteForm(context),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickActionButton(
                              icon: Icons.event_outlined,
                              label: '+ Event',
                              stuTheme: stuTheme,
                              onTap: () => StuDeskForms.showEventForm(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 5.5: Today's Plan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: _showAddPlanItemSheet,
                            child: Text(
                              '+ Add',
                              style: TextStyle(
                                color: stuTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (!hasTodayItems)
                        _buildEmptySection(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Your day is clear',
                          subtitle:
                              'Nothing scheduled for today yet. Add a class, task, or reminder to stay organized.',
                          actionText: 'Add to Plan',
                          onAction: _showAddPlanItemSheet,
                          stuTheme: stuTheme,
                        )
                      else ...[
                        // Today's Classes
                        ...todayClasses.map(
                          (c) => _buildClassTile(c, stuTheme),
                        ),
                        // Today's Exams
                        ...todayExams.map((e) => _buildExamTile(e, stuTheme)),
                        // Today's Events
                        ...todayEvents.map(
                          (ev) => _buildEventTile(ev, stuTheme),
                        ),
                        // Today's Tasks
                        ...todayTasks.map((t) => _buildTaskTile(t, stuTheme)),
                        // Today's Reminders
                        ...todayReminders.map(
                          (r) => _buildReminderTile(r, stuTheme),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Section 5.6: Coming Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Coming Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (_repo.exams.isNotEmpty)
                            Text(
                              '${_repo.exams.length} exams on radar',
                              style: TextStyle(
                                fontSize: 12,
                                color: stuTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (!hasUpcomingItems)
                        _buildEmptySection(
                          icon: Icons.event_note_rounded,
                          title: 'No upcoming deadlines',
                          subtitle:
                              'No exams or scheduled assignments in the near horizon. All caught up!',
                          actionText: 'Schedule Exam / Event',
                          onAction: () => StuDeskForms.showExamForm(context),
                          stuTheme: stuTheme,
                        )
                      else ...[
                        ...upcomingExams
                            .take(2)
                            .map((e) => _buildUpcomingExamTile(e, stuTheme)),
                        ...upcomingTasks
                            .take(3)
                            .map((t) => _buildUpcomingTaskTile(t, stuTheme)),
                        ...upcomingEvents
                            .take(2)
                            .map((ev) => _buildEventTile(ev, stuTheme)),
                      ],

                      const SizedBox(height: 28),

                      // Section 5.7: Quick Attendance Glance (Counts only - NO percentages!)
                      CustomCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: stuTheme.surfaceTier2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: stuTheme.border),
                              ),
                              child: Icon(
                                Icons.how_to_reg_rounded,
                                color: stuTheme.textPrimary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _repo.attendanceSummaryHeadline,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: stuTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _repo.attendanceSummaryDetail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: stuTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onNavigateToProfile,
                              child: Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: stuTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required IconData icon,
    required StuDeskThemeExtension stuTheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: stuTheme.textSecondary),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: stuTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: stuTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required StuDeskThemeExtension stuTheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: stuTheme.surfaceTier1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: stuTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: stuTheme.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: stuTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required StuDeskThemeExtension stuTheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stuTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stuTheme.surfaceTier2,
              shape: BoxShape.circle,
              border: Border.all(color: stuTheme.border),
            ),
            child: Icon(icon, color: stuTheme.textSecondary, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: stuTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: stuTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: stuTheme.accent,
              foregroundColor: stuTheme.onAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAction,
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(TimetableEntry c, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: stuTheme.border),
              ),
              child: Text(
                'CLASS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: stuTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.startTime} – ${c.endTime} • Room ${c.room}',
                    style: TextStyle(
                      fontSize: 12,
                      color: stuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: stuTheme.border),
              ),
              child: Text(
                c.courseCode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(TaskItem t, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => StuDeskForms.showTaskForm(context, existingTask: t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    t.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: t.isCompleted ? stuTheme.textMuted : stuTheme.textPrimary,
                    size: 22,
                  ),
                  onPressed: () => _repo.toggleTask(t.id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: t.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: t.isCompleted
                              ? stuTheme.textMuted
                              : stuTheme.textPrimary,
                        ),
                      ),
                      if (t.detail != null && t.detail!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          t.detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: stuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Task',
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: stuTheme.textMuted,
                  ),
                  onPressed: () =>
                      StuDeskForms.showTaskForm(context, existingTask: t),
                ),
                IconButton(
                  tooltip: 'Delete Task',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: stuTheme.textMuted,
                  ),
                  onPressed: () => StuDeskForms.confirmDelete(
                    context,
                    title: 'Delete Task',
                    message: 'Are you sure you want to delete "${t.title}"?',
                    onConfirm: () => _repo.deleteTask(t.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamTile(ExamItem e, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => StuDeskForms.showExamForm(context, existingExam: e),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: Text(
                    'EXAM TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: stuTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${e.courseCode} • Room ${e.room} • ${e.syllabusCutoff}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Exam',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: stuTheme.textMuted,
                  ),
                  onPressed: () => StuDeskForms.confirmDelete(
                    context,
                    title: 'Delete Exam',
                    message:
                        'Are you sure you want to delete exam "${e.title}"?',
                    onConfirm: () => _repo.deleteExam(e.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(EventItem ev, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => StuDeskForms.showEventForm(context, existingEvent: ev),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: Text(
                    'EVENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: stuTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d').format(ev.eventDate) +
                            (ev.location != null ? ' • ${ev.location}' : ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Event',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: stuTheme.textMuted,
                  ),
                  onPressed: () => StuDeskForms.confirmDelete(
                    context,
                    title: 'Delete Event',
                    message:
                        'Are you sure you want to delete event "${ev.title}"?',
                    onConfirm: () => _repo.deleteEvent(ev.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderTile(ReminderItem r, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              StuDeskForms.showReminderForm(context, existingReminder: r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: Text(
                    'REMINDER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: stuTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: stuTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Reminder',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: stuTheme.textMuted,
                  ),
                  onPressed: () => StuDeskForms.confirmDelete(
                    context,
                    title: 'Delete Reminder',
                    message: 'Are you sure you want to remove this reminder?',
                    onConfirm: () => _repo.deleteReminder(r.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingExamTile(ExamItem e, StuDeskThemeExtension stuTheme) {
    final diff = e.examDate.difference(DateTime.now()).inDays;
    final countdown = diff == 0
        ? 'Today'
        : (diff == 1 ? 'Tomorrow' : '$diff days left');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => StuDeskForms.showExamForm(context, existingExam: e),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: Text(
                    countdown.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: stuTheme.textPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM d').format(e.examDate)} • Room ${e.room}',
                        style: TextStyle(
                          fontSize: 12,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Exam',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: stuTheme.textMuted,
                  ),
                  onPressed: () => StuDeskForms.confirmDelete(
                    context,
                    title: 'Delete Exam',
                    message:
                        'Are you sure you want to delete exam "${e.title}"?',
                    onConfirm: () => _repo.deleteExam(e.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTaskTile(TaskItem t, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: stuTheme.surfaceTier1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => StuDeskForms.showTaskForm(context, existingTask: t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 20,
                  color: stuTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: stuTheme.textPrimary,
                    ),
                  ),
                ),
                if (t.dueDate != null)
                  Text(
                    DateFormat('MMM d').format(t.dueDate!),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: stuTheme.textSecondary,
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
