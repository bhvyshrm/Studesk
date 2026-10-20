import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
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
                color: stuTheme.accent,
                title: 'New Task',
                subtitle: 'Assignment or study task with due date',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddTaskDialog();
                },
              ),
              _buildAddTile(
                icon: Icons.calendar_today_rounded,
                color: stuTheme.accent,
                title: 'New Event',
                subtitle: 'Campus meeting, workshop, or event',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEventDialog();
                },
              ),
              _buildAddTile(
                icon: Icons.event_available_rounded,
                color: stuTheme.error,
                title: 'Upcoming Exam',
                subtitle: 'Midterm, quiz, or final exam date',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddExamDialog();
                },
              ),
              _buildAddTile(
                icon: Icons.alarm_rounded,
                color: stuTheme.warning,
                title: 'Quick Reminder',
                subtitle: 'Reminder for submission or preparation',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddReminderDialog();
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
    required Color color,
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
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
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
      trailing: Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary, size: 18),
      onTap: onTap,
    );
  }

  void _showAddTaskDialog() {
    final stuTheme = context.stuTheme;
    final titleCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TaskPriority priority = TaskPriority.normal;
    String selectedTag = _repo.courses.isNotEmpty ? _repo.courses.first.code : 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Text(
                'New Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g., Complete Trees lab submission',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailCtrl,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Optional details / instructions',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(DateFormat('MMM d').format(selectedDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<TaskPriority>(
                    value: priority,
                    dropdownColor: stuTheme.surfaceTier2,
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => priority = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final newTask = TaskItem(
                      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
                      title: title,
                      detail: detailCtrl.text.trim().isNotEmpty ? detailCtrl.text.trim() : null,
                      dueDate: selectedDate,
                      dueTime: DateFormat('h:mm a').format(DateTime.now()),
                      priority: priority,
                      categoryTag: selectedTag,
                      isCompleted: false,
                    );
                    await _repo.addTask(newTask);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    final stuTheme = context.stuTheme;
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Text(
                'New Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'e.g. ACM Seminar or Project Sync',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g. Auditorium B or Zoom',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormat('EEE, MMM d, yyyy').format(selectedDate)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 18),
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
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final newEvent = EventItem(
                      id: 'event_${DateTime.now().microsecondsSinceEpoch}',
                      title: title,
                      eventDate: selectedDate,
                      location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    );
                    await _repo.addEvent(newEvent);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Event', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExamDialog() {
    final stuTheme = context.stuTheme;
    final titleCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final cutoffCtrl = TextEditingController();
    DateTime examDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Text(
                'Add Exam',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Exam Title *',
                  hintText: 'e.g. Midterm Examination',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: courseCtrl,
                      style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Subject Code',
                        hintText: 'e.g. CS201',
                        filled: true,
                        fillColor: stuTheme.surfaceTier2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: roomCtrl,
                      style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Hall / Room',
                        hintText: 'e.g. Hall B-204',
                        filled: true,
                        fillColor: stuTheme.surfaceTier2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cutoffCtrl,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Syllabus Coverage / Notes',
                  hintText: 'e.g. Units 1 through 3',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormat('EEE, MMM d, yyyy').format(examDate)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: examDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => examDate = picked);
                  }
                },
              ),
              const SizedBox(height: 18),
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
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final newExam = ExamItem(
                      id: 'exam_${DateTime.now().microsecondsSinceEpoch}',
                      title: title,
                      courseCode: courseCtrl.text.trim().isNotEmpty ? courseCtrl.text.trim() : 'General',
                      room: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : 'TBA',
                      syllabusCutoff: cutoffCtrl.text.trim().isNotEmpty ? cutoffCtrl.text.trim() : 'Full Syllabus',
                      examDate: examDate,
                    );
                    await _repo.addExam(newExam);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    final stuTheme = context.stuTheme;
    final textCtrl = TextEditingController();
    DateTime selectedTime = DateTime.now().add(const Duration(hours: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Text(
                'Quick Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textCtrl,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Reminder Text *',
                  hintText: 'e.g. Return library book or review flashcards',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time_rounded, size: 16),
                label: Text(DateFormat('MMM d, h:mm a').format(selectedTime)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedTime),
                    );
                    if (time != null) {
                      setModalState(() {
                        selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 18),
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
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;
                    final reminder = ReminderItem(
                      id: 'rem_${DateTime.now().microsecondsSinceEpoch}',
                      text: text,
                      reminderTime: selectedTime,
                    );
                    await _repo.addReminder(reminder);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final profile = _repo.profile;
        final displayName = profile.effectiveDisplayName;

        // Today's aggregated records
        final todayClasses = _repo.todayClasses;
        final todayTasks = _repo.todayTasks;
        final todayExams = _repo.todayExams;
        final todayEvents = _repo.todayEvents;
        final todayReminders = _repo.todayReminders;

        final hasTodayItems = todayClasses.isNotEmpty ||
            todayTasks.isNotEmpty ||
            todayExams.isNotEmpty ||
            todayEvents.isNotEmpty ||
            todayReminders.isNotEmpty;

        // Nearest upcoming items
        final upcomingExams = _repo.exams.where((e) => e.examDate.isAfter(DateTime.now())).toList();
        final upcomingTasks = _repo.tasks.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isAfter(DateTime.now())).toList();
        final upcomingEvents = _repo.events.where((e) => e.eventDate.isAfter(DateTime.now())).toList();

        final hasUpcomingItems = upcomingExams.isNotEmpty || upcomingTasks.isNotEmpty || upcomingEvents.isNotEmpty;

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
                      // Section 7.1: Main Greeting below header
                      const SizedBox(height: 4),
                      Text(
                        'Good day, $displayName',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: stuTheme.textPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMotivationalPhrase(),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: stuTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 7.2: Today's Plan
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
                                color: stuTheme.accent,
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
                          subtitle: 'Nothing scheduled for today yet. Add a class, task, or reminder to stay organized.',
                          actionText: 'Add to Plan',
                          onAction: _showAddPlanItemSheet,
                          stuTheme: stuTheme,
                        )
                      else ...[
                        // Today's Classes
                        ...todayClasses.map((c) => _buildClassTile(c, stuTheme)),
                        // Today's Exams
                        ...todayExams.map((e) => _buildExamTile(e, stuTheme)),
                        // Today's Events
                        ...todayEvents.map((ev) => _buildEventTile(ev, stuTheme)),
                        // Today's Tasks
                        ...todayTasks.map((t) => _buildTaskTile(t, stuTheme)),
                        // Today's Reminders
                        ...todayReminders.map((r) => _buildReminderTile(r, stuTheme)),
                      ],

                      const SizedBox(height: 28),

                      // Section 7.3: Coming Up
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
                          subtitle: 'No exams or scheduled assignments in the near horizon. All caught up!',
                          actionText: 'Schedule Exam / Event',
                          onAction: _showAddExamDialog,
                          stuTheme: stuTheme,
                        )
                      else ...[
                        ...upcomingExams.take(2).map((e) => _buildUpcomingExamTile(e, stuTheme)),
                        ...upcomingTasks.take(3).map((t) => _buildUpcomingTaskTile(t, stuTheme)),
                        ...upcomingEvents.take(2).map((ev) => _buildEventTile(ev, stuTheme)),
                      ],

                      const SizedBox(height: 28),

                      // Section 7.4: Quick Attendance Glance (Counts only - NO percentages!)
                      CustomCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: stuTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.how_to_reg_rounded, color: stuTheme.accent, size: 22),
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
                                  color: stuTheme.accent,
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
            ),
            child: Icon(icon, color: stuTheme.textMuted, size: 22),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: stuTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.schedule_rounded, color: stuTheme.success, size: 20),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.border),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                t.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: t.isCompleted ? stuTheme.success : stuTheme.accent,
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
                      decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                      color: t.isCompleted ? stuTheme.textMuted : stuTheme.textPrimary,
                    ),
                  ),
                  if (t.detail != null && t.detail!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      t.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: stuTheme.textMuted),
              onPressed: () => _repo.deleteTask(t.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamTile(ExamItem e, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stuTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, color: stuTheme.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXAM TODAY: ${e.title}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.error,
                    ),
                  ),
                  Text(
                    '${e.courseCode} • Room ${e.room} • ${e.syllabusCutoff}',
                    style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(EventItem ev, StuDeskThemeExtension stuTheme) {
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: stuTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_month_rounded, color: stuTheme.accent, size: 20),
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
                    style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile(ReminderItem r, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_rounded, color: stuTheme.warning, size: 20),
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
              icon: Icon(Icons.close_rounded, size: 16, color: stuTheme.textMuted),
              onPressed: () => _repo.deleteReminder(r.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExamTile(ExamItem e, StuDeskThemeExtension stuTheme) {
    final diff = e.examDate.difference(DateTime.now()).inDays;
    final countdown = diff == 0 ? 'Today' : (diff == 1 ? 'Tomorrow' : '$diff days left');

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: stuTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                countdown,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.error,
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
                    style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTaskTile(TaskItem t, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment_outlined, size: 20, color: stuTheme.textSecondary),
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
                style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
