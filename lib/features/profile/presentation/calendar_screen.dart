import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        // Items on selected day
        final dayTasks = _repo.tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.year == _selectedDay.year &&
              t.dueDate!.month == _selectedDay.month &&
              t.dueDate!.day == _selectedDay.day;
        }).toList();

        final dayExams = _repo.exams.where((e) {
          return e.examDate.year == _selectedDay.year &&
              e.examDate.month == _selectedDay.month &&
              e.examDate.day == _selectedDay.day;
        }).toList();

        final dayEvents = _repo.events.where((e) {
          return e.eventDate.year == _selectedDay.year &&
              e.eventDate.month == _selectedDay.month &&
              e.eventDate.day == _selectedDay.day;
        }).toList();

        final dayReminders = _repo.reminders.where((r) {
          return r.reminderTime.year == _selectedDay.year &&
              r.reminderTime.month == _selectedDay.month &&
              r.reminderTime.day == _selectedDay.day;
        }).toList();

        final hasItems = dayTasks.isNotEmpty || dayExams.isNotEmpty || dayEvents.isNotEmpty || dayReminders.isNotEmpty;

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppBar(
            backgroundColor: stuTheme.canvas,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: stuTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Calendar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Month Selector Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left_rounded, color: stuTheme.textPrimary),
                            onPressed: _previousMonth,
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_focusedMonth),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right_rounded, color: stuTheme.textPrimary),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Month Grid Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: stuTheme.surfaceTier1,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: stuTheme.border),
                        ),
                        child: _buildMonthCalendar(stuTheme),
                      ),

                      const SizedBox(height: 24),

                      // Selected Day Heading
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(_selectedDay),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                          if (hasItems)
                            Text(
                              '${dayTasks.length + dayExams.length + dayEvents.length + dayReminders.length} items',
                              style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Items list on selected day
                      if (!hasItems)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: stuTheme.surfaceTier1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: stuTheme.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'No scheduled tasks, exams, or events for this date.',
                            style: TextStyle(fontSize: 13, color: stuTheme.textMuted),
                          ),
                        )
                      else ...[
                        ...dayExams.map((e) => _buildItemTile(
                              icon: Icons.event_available_rounded,
                              iconColor: stuTheme.error,
                              title: 'Exam: ${e.title}',
                              subtitle: '${e.courseCode} • Room ${e.room}',
                              stuTheme: stuTheme,
                            )),
                        ...dayEvents.map((ev) => _buildItemTile(
                              icon: Icons.calendar_month_rounded,
                              iconColor: stuTheme.accent,
                              title: ev.title,
                              subtitle: ev.location != null ? 'At ${ev.location}' : 'Campus Event',
                              stuTheme: stuTheme,
                            )),
                        ...dayTasks.map((t) => _buildItemTile(
                              icon: t.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              iconColor: t.isCompleted ? stuTheme.success : stuTheme.accent,
                              title: t.title,
                              subtitle: t.dueTime != null ? 'Due: ${t.dueTime}' : 'Task',
                              stuTheme: stuTheme,
                              onTap: () => _repo.toggleTask(t.id),
                            )),
                        ...dayReminders.map((r) => _buildItemTile(
                              icon: Icons.alarm_rounded,
                              iconColor: stuTheme.warning,
                              title: r.text,
                              subtitle: DateFormat('h:mm a').format(r.reminderTime),
                              stuTheme: stuTheme,
                            )),
                      ],

                      const SizedBox(height: 24),
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

  Widget _buildMonthCalendar(StuDeskThemeExtension stuTheme) {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = _focusedMonth.weekday; // 1 (Mon) - 7 (Sun)
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // Weekday abbreviations
        Row(
          children: weekDays.map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Grid of dates
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42, // 6 weeks
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final offset = firstWeekday - 1;
            final dayNumber = index - offset + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
            final isSelected = cellDate.year == _selectedDay.year &&
                cellDate.month == _selectedDay.month &&
                cellDate.day == _selectedDay.day;
            final isToday = cellDate.year == today.year &&
                cellDate.month == today.month &&
                cellDate.day == today.day;

            // Check if day has items
            final hasTask = _repo.tasks.any((t) =>
                t.dueDate != null &&
                t.dueDate!.year == cellDate.year &&
                t.dueDate!.month == cellDate.month &&
                t.dueDate!.day == cellDate.day);
            final hasExam = _repo.exams.any((e) =>
                e.examDate.year == cellDate.year &&
                e.examDate.month == cellDate.month &&
                e.examDate.day == cellDate.day);

            return InkWell(
              onTap: () => setState(() => _selectedDay = cellDate),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? stuTheme.accent : (isToday ? stuTheme.surfaceTier2 : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected ? Border.all(color: stuTheme.accent) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? stuTheme.onAccent : stuTheme.textPrimary,
                      ),
                    ),
                    if (hasTask || hasExam)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? stuTheme.onAccent
                                : (hasExam ? stuTheme.error : stuTheme.accent),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildItemTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required StuDeskThemeExtension stuTheme,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: stuTheme.surfaceTier1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: stuTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
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
