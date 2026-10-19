import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../journal/presentation/journal_editor_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  int _activeViewIndex = 0; // 0: Calendar & Tasks, 1: Daily Journal
  int _selectedDay = 3; // Thu 24

  final List<Map<String, dynamic>> _weekDays = [
    {'day': 'M', 'date': '21', 'dots': [Colors.grey]},
    {'day': 'T', 'date': '22', 'dots': [Colors.red, Colors.amber]},
    {'day': 'W', 'date': '23', 'dots': [Colors.green]},
    {'day': 'T', 'date': '24', 'dots': [Colors.red, Colors.amber, Colors.green]},
    {'day': 'F', 'date': '25', 'dots': [Colors.grey]},
    {'day': 'S', 'date': '26', 'dots': [Colors.amber]},
    {'day': 'S', 'date': '27', 'dots': []},
  ];

  late List<TaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = SampleData.getInitialTasks();
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppTopBar(
        title: 'Planner',
        subtitle: 'October 2024 • Week 43',
        actions: [
          IconButton(
            icon: Icon(Icons.auto_stories_rounded, color: stuTheme.accent, size: 20),
            tooltip: 'Open Daily Journal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: stuTheme.textSecondary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View Switcher Segmented Control
            _buildViewSwitcher(context),

            const SizedBox(height: 16),

            // Weekly Calendar Strip
            _buildWeeklyCalendarStrip(context),

            const SizedBox(height: 20),

            // Direct Journal Callout Banner
            _buildJournalCalloutBanner(context),

            const SizedBox(height: 20),

            // Timeline Schedule for Thursday, Oct 24
            _buildTimelineSchedule(context),

            const SizedBox(height: 20),

            // Today's Planner Checklist
            _buildTasksSection(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: stuTheme.surfaceTier2,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: stuTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeViewIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeViewIndex == 0 ? stuTheme.surfaceTier1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: _activeViewIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: _activeViewIndex == 0 ? stuTheme.accent : stuTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Calendar & Tasks',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _activeViewIndex == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _activeViewIndex == 0 ? stuTheme.textPrimary : stuTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: stuTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Daily Journal',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: stuTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendarStrip(BuildContext context) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Week 43',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '(Midterms Prep)',
                        style: TextStyle(
                          fontSize: 12,
                          color: stuTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.chevron_left_rounded, size: 20, color: stuTheme.textSecondary),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 20, color: stuTheme.textSecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-day row
          Row(
            children: List.generate(_weekDays.length, (index) {
              final item = _weekDays[index];
              final isSelected = _selectedDay == index;
              final dots = (item['dots'] as List).cast<Color>();

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? stuTheme.surfaceTier2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: stuTheme.accent, width: 1.2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          item['day'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? stuTheme.textPrimary : stuTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? stuTheme.accent : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              item['date'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? stuTheme.onAccent : stuTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots.map((dotColor) {
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCalloutBanner(BuildContext context) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stuTheme.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: stuTheme.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Daily Journal & Reflection',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    PillBadge(
                      label: '+1 Streak',
                      backgroundColor: stuTheme.successContainer,
                      textColor: stuTheme.success,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Record cognitive clarity, accomplishments & blockers',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_note_rounded,
            color: stuTheme.accent,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSchedule(BuildContext context) {
    final stuTheme = context.stuTheme;

    final timelineItems = [
      {
        'time': '09:00 AM',
        'title': 'Focus Block: LeetCode Practice',
        'subtitle': 'Trees & Two Pointers algorithm review',
        'type': 'focus',
        'color': stuTheme.success,
      },
      {
        'time': '10:15 AM',
        'title': 'CS201 Data Structures & Algorithms',
        'subtitle': 'Hall B-204 • Prof. Vance',
        'type': 'class',
        'color': stuTheme.accent,
      },
      {
        'time': '01:30 PM',
        'title': 'CS204 Digital Electronics Lab',
        'subtitle': 'Lab 3 • Breadboard ALU Simulation',
        'type': 'class',
        'color': stuTheme.accent,
      },
      {
        'time': '04:00 PM',
        'title': 'Group Study: DBMS Normalization',
        'subtitle': 'Library Room 4B • BCNF Practice',
        'type': 'study',
        'color': stuTheme.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline Schedule',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: stuTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timelineItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = timelineItems[index];
            final itemColor = item['color'] as Color;

            return CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              leadingIndicator: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    item['time'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: stuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Tasks & Deadlines',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: stuTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_tasks.where((t) => t.isCompleted).length} of ${_tasks.length} done',
              style: TextStyle(
                fontSize: 12,
                color: stuTheme.textSecondary,
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
              indent: 14,
              endIndent: 14,
            ),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return InkWell(
                onTap: () {
                  setState(() => task.isCompleted = !task.isCompleted);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: task.isCompleted ? stuTheme.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: task.isCompleted ? stuTheme.accent : stuTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted
                            ? Icon(Icons.check_rounded, size: 13, color: stuTheme.onAccent)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: task.isCompleted ? stuTheme.textSecondary : stuTheme.textPrimary,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (task.dueTime != null)
                        Text(
                          task.dueTime!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stuTheme.error,
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
}
