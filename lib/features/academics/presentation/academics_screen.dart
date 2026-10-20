import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';

class AcademicsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPlanner;

  const AcademicsScreen({
    super.key,
    this.onNavigateToPlanner,
  });

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> with SingleTickerProviderStateMixin {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  late TabController _tabController;

  final TextEditingController _notesSearchCtrl = TextEditingController();
  AcademicFileType? _selectedNoteTypeFilter;

  int _selectedTimetableDay = DateTime.now().weekday; // 1 (Mon) to 7 (Sun)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notesSearchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesSearchCtrl.dispose();
    super.dispose();
  }

  // --- Add Syllabus / Subject Dialog ---
  void _showAddSubjectDialog() {
    final stuTheme = context.stuTheme;
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    int credits = 3;

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
                'Add Subject & Syllabus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Subject Code * (e.g. CS201)',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Subject Title * (e.g. Data Structures & Algorithms)',
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
                      controller: profCtrl,
                      style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Professor',
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
                        labelText: 'Room / Hall',
                        filled: true,
                        fillColor: stuTheme.surfaceTier2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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
                    final code = codeCtrl.text.trim();
                    final title = titleCtrl.text.trim();
                    if (code.isEmpty || title.isEmpty) return;
                    final course = Course(
                      code: code,
                      title: title,
                      professor: profCtrl.text.trim().isNotEmpty ? profCtrl.text.trim() : 'Instructor',
                      department: 'Department',
                      schedule: 'TBA',
                      location: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : 'Classroom',
                      credits: credits,
                      attendedLectures: 0,
                      totalLectures: 0,
                    );
                    await _repo.addCourse(course);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Add Topic to Subject Dialog ---
  void _showAddTopicDialog(Course course) {
    final stuTheme = context.stuTheme;
    final topicCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              'Add Topic to ${course.code}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: topicCtrl,
              autofocus: true,
              style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Topic Title *',
                hintText: 'e.g. Binary Search Trees & AVL Rotations',
                filled: true,
                fillColor: stuTheme.surfaceTier2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleCtrl,
              style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Notes / Subtopics (Optional)',
                hintText: 'e.g. Chapter 4, search complexity',
                filled: true,
                fillColor: stuTheme.surfaceTier2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                  final text = topicCtrl.text.trim();
                  if (text.isEmpty) return;

                  final newTopic = UnitTopic(
                    id: 'top_${DateTime.now().microsecondsSinceEpoch}',
                    title: text,
                    subtitle: subtitleCtrl.text.trim(),
                    date: DateFormat('MMM d').format(DateTime.now()),
                    isCompleted: false,
                  );

                  List<CourseUnit> updatedUnits = List.from(course.units);
                  if (updatedUnits.isEmpty) {
                    updatedUnits.add(
                      CourseUnit(
                        unitNumber: 1,
                        title: 'Syllabus Core',
                        status: UnitStatus.current,
                        topics: [newTopic],
                      ),
                    );
                  } else {
                    final firstUnit = updatedUnits.first;
                    final newTopicsList = List<UnitTopic>.from(firstUnit.topics)..add(newTopic);
                    updatedUnits[0] = firstUnit.copyWith(topics: newTopicsList);
                  }

                  await _repo.updateCourse(course.copyWith(units: updatedUnits));
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add Topic', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Add Note Dialog ---
  void _showAddNoteDialog() {
    final stuTheme = context.stuTheme;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedCode = _repo.courses.isNotEmpty ? _repo.courses.first.code : 'General';
    AcademicFileType selectedType = AcademicFileType.note;

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
                'Create Academic Note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Note Title *',
                  hintText: 'e.g. Lecture 4: Process Synchronization',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCode,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        filled: true,
                        fillColor: stuTheme.surfaceTier2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'General', child: Text('General')),
                        ..._repo.courses.map((c) => DropdownMenuItem(value: c.code, child: Text(c.code))),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCode = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<AcademicFileType>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        filled: true,
                        fillColor: stuTheme.surfaceTier2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: AcademicFileType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Note Content / Summary',
                  hintText: 'Write academic formulas, key definitions, or lecture notes...',
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                    final note = AcademicNote(
                      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
                      title: title,
                      subjectCode: selectedCode,
                      fileType: selectedType,
                      content: contentCtrl.text.trim(),
                    );
                    await _repo.addAcademicNote(note);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Academic Note', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Add Timetable Entry Dialog ---
  void _showAddTimetableDialog() {
    final stuTheme = context.stuTheme;
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 30);
    int selectedDay = _selectedTimetableDay;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Timetable Class',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Class / Subject Title *',
                    hintText: 'e.g. Operating Systems Lab',
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
                        controller: codeCtrl,
                        style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Code',
                          hintText: 'CS204',
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
                          labelText: 'Room',
                          hintText: 'Lab 2',
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
                  controller: profCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Professor / Instructor',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: startTime);
                          if (picked != null) setModalState(() => startTime = picked);
                        },
                        child: Text('Start: ${startTime.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: endTime);
                          if (picked != null) setModalState(() => endTime = picked);
                        },
                        child: Text('End: ${endTime.format(context)}'),
                      ),
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
                      final entry = TimetableEntry(
                        id: 'tt_${DateTime.now().microsecondsSinceEpoch}',
                        dayOfWeek: selectedDay,
                        startTime: startTime.format(context),
                        endTime: endTime.format(context),
                        courseCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'Class',
                        title: title,
                        room: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : 'Hall',
                        professor: profCtrl.text.trim().isNotEmpty ? profCtrl.text.trim() : 'Instructor',
                      );
                      await _repo.addTimetableEntry(entry);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Timetable Class', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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
        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppTopBar(
            showBrandWordmark: true,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Secondary 3-tab navigation: Syllabus, Notes, Timetable
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: stuTheme.accent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: stuTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: stuTheme.onAccent,
                    unselectedLabelColor: stuTheme.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Syllabus'),
                      Tab(text: 'Notes'),
                      Tab(text: 'Timetable'),
                    ],
                  ),
                ),

                // Subsections Body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSyllabusTab(stuTheme),
                      _buildNotesTab(stuTheme),
                      _buildTimetableTab(stuTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= 8.1 SYLLABUS SUBSECTION =================
  Widget _buildSyllabusTab(StuDeskThemeExtension stuTheme) {
    final courses = _repo.courses;

    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: stuTheme.surfaceTier2, shape: BoxShape.circle),
                child: Icon(Icons.school_outlined, size: 28, color: stuTheme.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'No subjects added yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your academic subjects and topics to manage your semester syllabus without percentage clutter.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: stuTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: stuTheme.accent,
                  foregroundColor: stuTheme.onAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _showAddSubjectDialog,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final remaining = course.remainingTopics;
        final total = course.totalTopics;

        String statusSummary = total == 0
            ? 'No topics listed'
            : (remaining == 0 ? 'All topics completed' : '$remaining topics left');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: stuTheme.surfaceTier1,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: stuTheme.border),
            ),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stuTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: stuTheme.accent, size: 20),
              ),
              title: Text(
                course.title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
              ),
              subtitle: Text(
                '${course.code} • $statusSummary',
                style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: stuTheme.textSecondary, size: 20),
                color: stuTheme.surfaceTier2,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'add_topic', child: Text('Add Topic')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Subject', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (val) {
                  if (val == 'add_topic') {
                    _showAddTopicDialog(course);
                  } else if (val == 'delete') {
                    _repo.deleteCourse(course.code);
                  }
                },
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      if (course.units.isEmpty || course.units.every((u) => u.topics.isEmpty))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No topics added. Tap "Add Topic" to list concepts.',
                            style: TextStyle(fontSize: 12.5, color: stuTheme.textMuted),
                          ),
                        )
                      else
                        ...course.units.expand((unit) {
                          return unit.topics.map((topic) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                topic.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                                  color: topic.isCompleted ? stuTheme.textMuted : stuTheme.textPrimary,
                                ),
                              ),
                              subtitle: topic.subtitle.isNotEmpty
                                  ? Text(topic.subtitle, style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary))
                                  : null,
                              value: topic.isCompleted,
                              activeColor: stuTheme.accent,
                              checkColor: stuTheme.onAccent,
                              onChanged: (_) {
                                _repo.toggleTopicCompletion(course.code, unit.unitNumber, topic.id);
                              },
                            );
                          });
                        }),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Topic'),
                          onPressed: () => _showAddTopicDialog(course),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= 8.2 NOTES & FILES SUBSECTION =================
  Widget _buildNotesTab(StuDeskThemeExtension stuTheme) {
    final notes = _repo.notes.where((n) {
      final query = _notesSearchCtrl.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        if (!n.title.toLowerCase().contains(query) &&
            !n.content.toLowerCase().contains(query) &&
            !n.subjectCode.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_selectedNoteTypeFilter != null) {
        if (n.fileType != _selectedNoteTypeFilter) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _notesSearchCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search notes by title or content...',
                    hintStyle: TextStyle(color: stuTheme.textMuted, fontSize: 12.5),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier1,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: stuTheme.accent, foregroundColor: stuTheme.onAccent),
                icon: const Icon(Icons.add_rounded),
                onPressed: _showAddNoteDialog,
              ),
            ],
          ),
        ),

        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedNoteTypeFilter == null,
                  onSelected: (_) => setState(() => _selectedNoteTypeFilter = null),
                ),
              ),
              ...AcademicFileType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.name.toUpperCase()),
                    selected: _selectedNoteTypeFilter == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedNoteTypeFilter = selected ? type : null;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, size: 36, color: stuTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No academic notes yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Store coursework notes, summaries, and revision guides here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: stuTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: stuTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.notes_rounded, color: stuTheme.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${note.subjectCode} • ${DateFormat('MMM d').format(note.createdAt)}',
                                  style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
                                ),
                                if (note.content.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.5, color: stuTheme.textPrimary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: stuTheme.textMuted, size: 18),
                            onPressed: () => _repo.deleteAcademicNote(note.id),
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

  // ================= 8.3 TIMETABLE SUBSECTION =================
  Widget _buildTimetableTab(StuDeskThemeExtension stuTheme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final entries = _repo.getTimetableForDay(_selectedTimetableDay);

    return Column(
      children: [
        // Day of week selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: List.generate(7, (i) {
              final dayIndex = i + 1;
              final isSelected = _selectedTimetableDay == dayIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTimetableDay = dayIndex),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? stuTheme.accent : stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : stuTheme.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? stuTheme.onAccent : stuTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${days[_selectedTimetableDay - 1]} Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Class'),
                onPressed: _showAddTimetableDialog,
              ),
            ],
          ),
        ),

        // Entries List or Empty State
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.free_breakfast_outlined, size: 36, color: stuTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No classes scheduled',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Free day or no entries added for ${days[_selectedTimetableDay - 1]}.',
                          style: TextStyle(fontSize: 13, color: stuTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: stuTheme.surfaceTier2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item.startTime,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                                ),
                                Text(
                                  item.endTime,
                                  style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.courseCode} • Room ${item.room} • ${item.professor}',
                                  style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: stuTheme.textMuted),
                            onPressed: () => _repo.deleteTimetableEntry(item.id),
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
