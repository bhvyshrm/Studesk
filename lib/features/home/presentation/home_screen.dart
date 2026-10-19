import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/circular_gauge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../journal/presentation/journal_editor_screen.dart';
import '../../subjects/presentation/subject_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToAcademics;
  final VoidCallback onNavigateToPlanner;

  const HomeScreen({
    super.key,
    required this.onNavigateToAcademics,
    required this.onNavigateToPlanner,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<TaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = SampleData.getInitialTasks();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  void _showMarkAttendDialog() {
    final stuTheme = context.stuTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: stuTheme.surfaceTier1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mark Attendance',
          style: TextStyle(
            color: stuTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Mark yourself present for Data Structures & Algorithms (10:15 - 11:45 AM)?',
          style: TextStyle(color: stuTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: stuTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: stuTheme.accent,
              foregroundColor: stuTheme.onAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: stuTheme.surfaceTier3,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    'Attendance logged for CS201 (+1 class)',
                    style: TextStyle(color: stuTheme.textPrimary),
                  ),
                ),
              );
            },
            child: const Text('Confirm Present'),
          ),
        ],
      ),
    );
  }

  void _showPomodoroDialog() {
    final stuTheme = context.stuTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: stuTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.timer_rounded, size: 48, color: stuTheme.accent),
              const SizedBox(height: 12),
              Text(
                '25:00 Focus Block',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data Structures & Algorithms - Trees Revision',
                style: TextStyle(fontSize: 14, color: stuTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stuTheme.accent,
                    foregroundColor: stuTheme.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: stuTheme.surfaceTier3,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Pomodoro timer started for 25 minutes',
                          style: TextStyle(color: stuTheme.textPrimary),
                        ),
                      ),
                    );
                  },
                  child: const Text('Start Focus Session', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppTopBar(
        title: 'Good Morning, Alex',
        subtitle: 'CS Year 2 • Thu, Oct 24',
        onCalendarTap: widget.onNavigateToPlanner,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 300));
        },
        color: stuTheme.accent,
        backgroundColor: stuTheme.surfaceTier1,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Performance Ribbon: 3 Bento Cards
              _buildPerformanceRibbon(context),

              const SizedBox(height: 20),

              // 2. Today's Schedule Timeline Module
              _buildScheduleModule(context),

              const SizedBox(height: 20),

              // 3. Today's Priorities Checklist
              _buildPrioritiesSection(context),

              const SizedBox(height: 20),

              // 4. Quick Tools Horizontal Bar
              _buildQuickToolsBar(context),

              const SizedBox(height: 20),

              // 5. Exam Radar Bento Card
              _buildExamRadarCard(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceRibbon(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Row(
      children: [
        // 12-day Streak
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: stuTheme.accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        size: 15,
                        color: stuTheme.accent,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'STREAK',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.accent,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: '12 ',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: 'days',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'On track today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Attendance Status
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
            onTap: widget.onNavigateToAcademics,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: stuTheme.success.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: stuTheme.success,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'ATTEND',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.success,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '88%',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Safe status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: stuTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Study Goals
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
            onTap: widget.onNavigateToPlanner,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier2,
                        shape: BoxShape.circle,
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        size: 15,
                        color: stuTheme.accent,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'GOALS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: '3 ',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '/ 5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '2 tasks left',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleModule(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Today's Schedule",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: stuTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onNavigateToPlanner,
              child: Text(
                'Full Timetable',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: stuTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Primary Active Lecture Card (DSA)
        CustomCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
          leadingIndicator: Container(
            width: 4,
            decoration: BoxDecoration(
              color: stuTheme.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PillBadge(
                          label: 'Starts in 20m • Hall B-204',
                          icon: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: stuTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
                          textColor: stuTheme.accent,
                          borderColor: stuTheme.accent.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data Structures & Algorithms',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '10:15 AM – 11:45 AM • Prof. Vance',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: stuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stuTheme.border),
                    ),
                    child: Icon(
                      Icons.terminal_rounded,
                      color: stuTheme.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: stuTheme.border,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: stuTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Trees & Binary Heaps',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubjectDetailsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: stuTheme.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Syllabus',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: stuTheme.onAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: stuTheme.onAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Upcoming Class Card
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  color: stuTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Electronics',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '01:30 PM – 03:00 PM • Lab 3',
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
                ),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritiesSection(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      "Today's Priorities",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: stuTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${_tasks.where((t) => !t.isCompleted).length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: stuTheme.surfaceTier3,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Add new task sheet',
                      style: TextStyle(color: stuTheme.textPrimary),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: stuTheme.accent),
                  const SizedBox(width: 2),
                  Text(
                    'Task',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: stuTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        CustomCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            separatorBuilder: (_, _) => Divider(
              color: stuTheme.border,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return InkWell(
                onTap: () => _toggleTask(index),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interactive Checkbox
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? stuTheme.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: task.isCompleted
                                ? stuTheme.accent
                                : stuTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: stuTheme.onAccent,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: task.isCompleted
                                          ? stuTheme.textSecondary
                                          : stuTheme.textPrimary,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildPriorityBadge(task.priority, stuTheme),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                if (task.dueTime != null) ...[
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: stuTheme.error,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.dueTime!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: stuTheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: stuTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  task.categoryTag,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: stuTheme.textSecondary,
                                  ),
                                ),
                                if (task.detail != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: stuTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.detail!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: stuTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority, StuDeskThemeExtension stuTheme) {
    switch (priority) {
      case TaskPriority.high:
        return PillBadge(
          label: 'High',
          backgroundColor: stuTheme.errorContainer,
          textColor: stuTheme.error,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        );
      case TaskPriority.academic:
        return PillBadge(
          label: 'Academic',
          backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
          textColor: stuTheme.accent,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        );
      case TaskPriority.review:
        return PillBadge(
          label: 'Review',
          backgroundColor: stuTheme.successContainer,
          textColor: stuTheme.success,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        );
      case TaskPriority.normal:
        return PillBadge(
          label: 'General',
          backgroundColor: stuTheme.surfaceTier2,
          textColor: stuTheme.textSecondary,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        );
    }
  }

  Widget _buildQuickToolsBar(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tools',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: stuTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildToolButton(
                icon: Icons.add_task_rounded,
                iconColor: stuTheme.accent,
                label: 'Add Task',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: stuTheme.surfaceTier3,
                      behavior: SnackBarBehavior.floating,
                      content: Text('Quick Task Creator', style: TextStyle(color: stuTheme.textPrimary)),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildToolButton(
                icon: Icons.edit_note_rounded,
                iconColor: stuTheme.accent,
                label: 'Quick Note',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JournalEditorScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildToolButton(
                icon: Icons.how_to_reg_rounded,
                iconColor: stuTheme.success,
                label: 'Mark Attend',
                onTap: _showMarkAttendDialog,
              ),
              const SizedBox(width: 8),
              _buildToolButton(
                icon: Icons.timer_rounded,
                iconColor: stuTheme.onAccent,
                label: 'Pomodoro 25m',
                isHighlight: true,
                onTap: _showPomodoroDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    final stuTheme = context.stuTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlight ? stuTheme.accent : stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlight ? stuTheme.accent : stuTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isHighlight ? stuTheme.onAccent : iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? stuTheme.onAccent : stuTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamRadarCard(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Exam Radar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: stuTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View all (3)',
              style: TextStyle(
                fontSize: 12.5,
                color: stuTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillBadge(
                      label: 'In 4 Days • Mon, Oct 28',
                      icon: Icon(
                        Icons.alarm_rounded,
                        size: 13,
                        color: stuTheme.accent,
                      ),
                      backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
                      textColor: stuTheme.accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Database Management Systems',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Midterm Exam • Relational Algebra, SQL & Normalization',
                      style: TextStyle(
                        fontSize: 12,
                        color: stuTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              CircularGauge(
                percentage: 72.0,
                size: 64,
                strokeWidth: 5,
                trackColor: stuTheme.surfaceTier2,
                progressColor: stuTheme.accent,
                label: '72%',
                sublabel: 'PREP',
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
                sublabelStyle: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
