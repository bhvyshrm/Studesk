import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
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
  final StuDeskRepository _repo = StuDeskRepository.instance;
  int _activeViewIndex = 0; // 0: Calendar & Tasks, 1: Daily Journal
  int _selectedDayIndex = 0; // 0 to 6
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Monday of current week
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex = now.weekday - 1;
  }

  void _showAddTaskSheet() {
    final stuTheme = context.stuTheme;
    final titleController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.academic;
    String selectedTag = _repo.courses.isNotEmpty ? _repo.courses.first.code : 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              const SizedBox(height: 18),
              Text(
                'Create Academic Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g., Read OS Lab Chapter 3...',
                  hintStyle: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Priority: ', style: TextStyle(color: stuTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<TaskPriority>(
                    value: selectedPriority,
                    dropdownColor: stuTheme.surfaceTier2,
                    underline: const SizedBox(),
                    items: TaskPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.name.toUpperCase(),
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedPriority = val);
                    },
                  ),
                  const Spacer(),
                  Text('Course: ', style: TextStyle(color: stuTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedTag,
                    dropdownColor: stuTheme.surfaceTier2,
                    underline: const SizedBox(),
                    items: [
                      ..._repo.courses.map((c) => DropdownMenuItem(value: c.code, child: Text(c.code))),
                      if (_repo.courses.every((c) => c.code != 'General'))
                        const DropdownMenuItem(value: 'General', child: Text('General')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedTag = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stuTheme.accent,
                    foregroundColor: stuTheme.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final text = titleController.text.trim();
                    if (text.isNotEmpty) {
                      final newTask = TaskItem(
                        id: 'tsk_${DateTime.now().microsecondsSinceEpoch}',
                        title: text,
                        priority: selectedPriority,
                        categoryTag: selectedTag,
                        dueTime: 'Tonight 11:59 PM',
                        isCompleted: false,
                      );
                      await _repo.addTask(newTask);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: stuTheme.surfaceTier3,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Task added to Planner', style: TextStyle(color: stuTheme.textPrimary)),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final tasks = _repo.tasks;
        final selectedDayOfWeek = _selectedDayIndex + 1; // 1 = Monday
        final selectedDate = _weekStart.add(Duration(days: _selectedDayIndex));
        final dayTimetable = _repo.getTimetableForDay(selectedDayOfWeek);

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppTopBar(
            title: 'Planner',
            subtitle: DateFormat('MMMM yyyy • \'Week\' w').format(DateTime.now()),
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
                icon: Icon(Icons.add_task_rounded, color: stuTheme.accent, size: 20),
                tooltip: 'Add Task',
                onPressed: _showAddTaskSheet,
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
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

                // Timeline Schedule for Selected Day
                _buildTimelineSchedule(context, selectedDate, dayTimetable),

                const SizedBox(height: 20),

                // Planner Tasks Checklist
                _buildTasksSection(context, tasks),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  },
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
    final now = DateTime.now();

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
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        DateFormat('• MMMM yyyy').format(_weekStart),
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
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, size: 20, color: stuTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _weekStart = _weekStart.subtract(const Duration(days: 7));
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, size: 20, color: stuTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _weekStart = _weekStart.add(const Duration(days: 7));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-day row
          Row(
            children: List.generate(7, (index) {
              final date = _weekStart.add(Duration(days: index));
              final isSelected = _selectedDayIndex == index;
              final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
              final dayTimetable = _repo.getTimetableForDay(index + 1);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDayIndex = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? stuTheme.surfaceTier2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: stuTheme.accent, width: 1.2)
                          : (isToday ? Border.all(color: stuTheme.border) : null),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
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
                              '${date.day}',
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
                          children: [
                            if (dayTimetable.isNotEmpty)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected ? stuTheme.accent : stuTheme.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.accent.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: stuTheme.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_stories_rounded, color: stuTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Reflection & Study Log',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track what you learned today and extend your streak',
                    style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSchedule(BuildContext context, DateTime date, List<TimetableEntry> entries) {
    final stuTheme = context.stuTheme;
    final dateStr = DateFormat('EEEE, MMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Timeline Schedule',
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
              dateStr,
              style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (entries.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.weekend_rounded, color: stuTheme.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No scheduled lectures for this day.',
                    style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = entries[index];

              return CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                leadingIndicator: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: index == 0 ? stuTheme.accent : stuTheme.surfaceTier3,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      item.startTime,
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
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.room} • ${item.professor}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PillBadge(
                      label: item.courseCode,
                      backgroundColor: stuTheme.surfaceTier2,
                      textColor: stuTheme.textPrimary,
                      fontSize: 11,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context, List<TaskItem> tasks) {
    final stuTheme = context.stuTheme;
    final doneCount = tasks.where((t) => t.isCompleted).length;

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
            GestureDetector(
              onTap: _showAddTaskSheet,
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: stuTheme.accent),
                  const SizedBox(width: 2),
                  Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$doneCount of ${tasks.length} tasks completed',
          style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
        ),
        const SizedBox(height: 10),

        if (tasks.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No tasks left! Tap "+ Add Task" to plan your study.',
                style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          CustomCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => Divider(
                color: stuTheme.border,
                height: 1,
                indent: 14,
                endIndent: 14,
              ),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _repo.toggleTask(task.id),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: task.isCompleted ? stuTheme.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: task.isCompleted ? stuTheme.accent : stuTheme.border,
                              width: 1.5,
                            ),
                          ),
                          child: task.isCompleted
                              ? Icon(Icons.check_rounded, size: 14, color: stuTheme.onAccent)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: task.isCompleted ? stuTheme.textSecondary : stuTheme.textPrimary,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (task.categoryTag.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${task.categoryTag} • ${task.priority.name.toUpperCase()}',
                                style: TextStyle(fontSize: 10.5, color: stuTheme.textSecondary),
                              ),
                            ],
                          ],
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
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 16, color: stuTheme.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _repo.deleteTask(task.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
