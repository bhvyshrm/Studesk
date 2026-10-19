import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../subjects/presentation/subject_details_screen.dart';

class AcademicsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPlanner;

  const AcademicsScreen({
    super.key,
    this.onNavigateToPlanner,
  });

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  int _selectedTab = 0; // 0: Overview & Subjects, 1: Attendance Tracker, 2: Syllabus & Units

  final List<String> _tabs = [
    'Overview & Subjects',
    'Attendance Tracker',
    'Syllabus & Units',
  ];

  void _showAddSubjectDialog() {
    final stuTheme = context.stuTheme;
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final schedCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    int credits = 4;

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
          child: SingleChildScrollView(
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
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: stuTheme.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.school_rounded, color: stuTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Enrolled Subject',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Subject Code (e.g., CS301)',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
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
                    labelText: 'Subject Title (e.g., Database Systems)',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: profCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Instructor / Professor',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: schedCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Schedule (e.g., Mon, Wed 10:15 - 11:45 AM)',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Classroom / Lab Location',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                      final code = codeCtrl.text.trim().toUpperCase();
                      final title = titleCtrl.text.trim();
                      if (code.isNotEmpty && title.isNotEmpty) {
                        final newCourse = Course(
                          code: code,
                          title: title,
                          professor: profCtrl.text.trim().isNotEmpty ? profCtrl.text.trim() : 'Instructor',
                          department: 'Computer Science & Engineering',
                          credits: credits,
                          attendancePercent: 100.0,
                          attendedLectures: 0,
                          totalLectures: 0,
                          standing: 'Good Standing',
                          isWarning: false,
                          schedule: schedCtrl.text.trim().isNotEmpty ? schedCtrl.text.trim() : 'TBA',
                          location: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : 'Campus Hall',
                          lastTopic: 'Introduction & Course Objectives',
                          grade: 'A',
                          units: [
                            CourseUnit(
                              unitNumber: 1,
                              title: 'Foundations & Core Principles',
                              status: UnitStatus.completed,
                              topics: [
                                UnitTopic(
                                  id: 'top_${DateTime.now().microsecondsSinceEpoch}_1',
                                  title: 'Course Introduction & Basics',
                                  subtitle: 'Overview of syllabus & reference materials',
                                  isCompleted: true,
                                  date: 'Week 1',
                                ),
                                UnitTopic(
                                  id: 'top_${DateTime.now().microsecondsSinceEpoch}_2',
                                  title: 'Theoretical Framework',
                                  subtitle: 'Core definitions and initial problem sets',
                                  isCompleted: false,
                                  date: 'Week 2',
                                ),
                              ],
                            ),
                            CourseUnit(
                              unitNumber: 2,
                              title: 'Advanced Applications & Analysis',
                              status: UnitStatus.current,
                              topics: [
                                UnitTopic(
                                  id: 'top_${DateTime.now().microsecondsSinceEpoch}_3',
                                  title: 'Practical Case Studies',
                                  subtitle: 'Lab exercises and computational models',
                                  isCompleted: false,
                                  date: 'Week 3',
                                ),
                              ],
                            ),
                          ],
                        );
                        await _repo.addCourse(newCourse);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: stuTheme.surfaceTier3,
                              behavior: SnackBarBehavior.floating,
                              content: Text('Course $code enrolled successfully!', style: TextStyle(color: stuTheme.textPrimary)),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Enroll Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteCourseDialog(Course course) {
    final stuTheme = context.stuTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: stuTheme.surfaceTier1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Subject',
          style: TextStyle(color: stuTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${course.title} (${course.code})? All associated syllabus units and lecture logs will be permanently removed.',
          style: TextStyle(color: stuTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: stuTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: stuTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.deleteCourse(course.code);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: stuTheme.surfaceTier3,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Deleted ${course.code} from registered courses',
                      style: TextStyle(color: stuTheme.textPrimary),
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete Course'),
          ),
        ],
      ),
    );
  }

  void _showMarkTodayDialog() {
    final stuTheme = context.stuTheme;
    if (_repo.courses.isEmpty) return;

    String selectedCourseCode = _repo.courses.first.code;
    bool isPresent = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: stuTheme.surfaceTier1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Mark Today\'s Attendance',
            style: TextStyle(
              color: stuTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select lecture to log presence:',
                style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ..._repo.courses.map((c) {
                final isSel = selectedCourseCode == c.code;
                return GestureDetector(
                  onTap: () => setDlgState(() => selectedCourseCode = c.code),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? stuTheme.accent.withValues(alpha: 0.15) : stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? stuTheme.accent : stuTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: isSel ? stuTheme.accent : stuTheme.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${c.code} - ${c.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Present')),
                      selected: isPresent,
                      selectedColor: stuTheme.successContainer,
                      labelStyle: TextStyle(
                        color: isPresent ? stuTheme.success : stuTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setDlgState(() => isPresent = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Absent')),
                      selected: !isPresent,
                      selectedColor: stuTheme.errorContainer,
                      labelStyle: TextStyle(
                        color: !isPresent ? stuTheme.error : stuTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setDlgState(() => isPresent = false),
                    ),
                  ),
                ],
              ),
            ],
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                await _repo.logSubjectAttendance(
                  selectedCourseCode,
                  isPresent: isPresent,
                  slot: 'Lecture',
                  topic: 'Regular class',
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: stuTheme.surfaceTier3,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Recorded ${isPresent ? "Present" : "Absent"} for $selectedCourseCode. Semester attendance updated!',
                      style: TextStyle(color: stuTheme.textPrimary),
                    ),
                  ),
                );
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkCollegeAttendanceDialog(DateTime date) {
    final stuTheme = context.stuTheme;
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(date);
    final existingStatus = _repo.getCollegeAttendanceForDate(date);
    bool isPresent = existingStatus ?? true;
    final remarksCtrl = TextEditingController(
      text: existingStatus == true ? 'On campus all day' : 'Leave / Personal',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: stuTheme.surfaceTier1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'College Day Attendance',
            style: TextStyle(color: stuTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log campus attendance for $dateStr:',
                style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Attended Campus')),
                      selected: isPresent,
                      selectedColor: stuTheme.successContainer,
                      labelStyle: TextStyle(
                        color: isPresent ? stuTheme.success : stuTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setDlgState(() => isPresent = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Absent / Off')),
                      selected: !isPresent,
                      selectedColor: stuTheme.errorContainer,
                      labelStyle: TextStyle(
                        color: !isPresent ? stuTheme.error : stuTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setDlgState(() => isPresent = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: remarksCtrl,
                style: TextStyle(color: stuTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Remarks / Notes',
                  labelStyle: TextStyle(color: stuTheme.textSecondary),
                  filled: true,
                  fillColor: stuTheme.surfaceTier2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                await _repo.logCollegeAttendance(
                  date,
                  isPresent,
                  remarks: remarksCtrl.text.trim(),
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: stuTheme.surfaceTier3,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'College daily record saved for $dateStr',
                      style: TextStyle(color: stuTheme.textPrimary),
                    ),
                  ),
                );
              },
              child: const Text('Save Record'),
            ),
          ],
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

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppTopBar(
            title: 'Academics',
            titleTrailing: PillBadge(
              label: profile.semester,
              backgroundColor: stuTheme.accent.withValues(alpha: 0.18),
              textColor: stuTheme.accent,
            ),
            subtitle: '${profile.course} • Academic Year',
            onCalendarTap: widget.onNavigateToPlanner,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented Tab Controls
                _buildSegmentedTabs(context),

                const SizedBox(height: 16),

                if (_selectedTab == 0) ...[
                  // 1. Semester Attendance KPI Card
                  _buildAttendanceKPICard(context),

                  const SizedBox(height: 20),

                  // 2. Weekly Schedule Strip & Today's lectures
                  _buildWeeklyScheduleStrip(context),

                  const SizedBox(height: 20),

                  // 3. Registered Courses Section
                  _buildRegisteredCourses(context),
                ] else if (_selectedTab == 1) ...[
                  // Dedicated Attendance Tracker View
                  _buildCollegeAttendanceSection(context),

                  const SizedBox(height: 20),

                  _buildSubjectAttendanceTrackerSection(context),

                  const SizedBox(height: 20),

                  _buildAttendanceProjectionSection(context),
                ] else ...[
                  // Dedicated Syllabus & Units View
                  _buildSyllabusOverviewSection(context),
                ],

                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedTabs(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: stuTheme.surfaceTier2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stuTheme.border),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? stuTheme.surfaceTier1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? stuTheme.textPrimary : stuTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAttendanceKPICard(BuildContext context) {
    final stuTheme = context.stuTheme;
    final overallPct = _repo.overallAttendancePercentage;
    final isSafe = overallPct >= 75.0;
    final attended = _repo.totalAttendedLectures;
    final total = _repo.totalLectures;
    final safeMissable = _repo.safeMissableClasses;
    final neededFor75 = _repo.classesNeededFor75;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'SEMESTER ATTENDANCE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: stuTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isSafe ? stuTheme.success : stuTheme.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${overallPct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isSafe ? stuTheme.textPrimary : stuTheme.warning,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ 75% Target',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        text: '$attended ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: 'of $total total lectures completed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Mark Today CTA Button
              ElevatedButton.icon(
                onPressed: _showMarkTodayDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: stuTheme.accent,
                  foregroundColor: stuTheme.onAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Mark Today',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hairline Tracker with 75% baseline marker
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (overallPct / 100.0).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSafe ? stuTheme.accent : stuTheme.warning,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
              ),
              Text(
                'Min Target: 75%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSafe ? stuTheme.success : stuTheme.warning,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Safe Class Projection Inset Module
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stuTheme.surfaceTier2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isSafe ? stuTheme.accent : stuTheme.warning).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSafe ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                    size: 18,
                    color: isSafe ? stuTheme.accent : stuTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSafe
                            ? 'You can safely miss up to $safeMissable classes while maintaining >75% target'
                            : 'Attendance below target! Attend next $neededFor75 classes to reach 75%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Dynamic calculation protecting semester final examination eligibility.',
                        style: TextStyle(
                          fontSize: 11,
                          color: stuTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleStrip(BuildContext context) {
    final stuTheme = context.stuTheme;
    final timetable = _repo.timetable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Timetable & Lectures",
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
              onTap: widget.onNavigateToPlanner,
              child: Text(
                'Full Planner',
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

        if (timetable.isEmpty) ...[
          CustomCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              'No timetable lectures configured yet.',
              style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timetable.take(2).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = timetable[index];
              return CustomCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 38,
                      decoration: BoxDecoration(
                        color: index == 0 ? stuTheme.success : stuTheme.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            '${item.startTime} - ${item.endTime} • ${item.room} (${item.professor})',
                            style: TextStyle(
                              fontSize: 12,
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
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRegisteredCourses(BuildContext context) {
    final stuTheme = context.stuTheme;
    final courses = _repo.courses;

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
                      'Registered Courses',
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
                    '${courses.length} Enrolled',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: stuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showAddSubjectDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stuTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: stuTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: stuTheme.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Add Subject',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (courses.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No subjects enrolled. Tap "+ Add Subject" to get started.',
                style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final course = courses[index];
              return CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    course.code,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: stuTheme.accent,
                                    ),
                                  ),
                                  if (course.isWarning)
                                    PillBadge(
                                      label: 'Attendance Warning',
                                      backgroundColor: stuTheme.warningContainer,
                                      textColor: stuTheme.warning,
                                      fontSize: 10,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course.title,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: stuTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${course.professor} • ${course.schedule}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: stuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${course.attendancePercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: course.isWarning
                                    ? stuTheme.warning
                                    : stuTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  course.isWarning
                                      ? Icons.warning_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 12,
                                  color: course.isWarning
                                      ? stuTheme.warning
                                      : stuTheme.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  course.standing,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: course.isWarning
                                        ? stuTheme.warning
                                        : stuTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Syllabus Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Syllabus: ${course.completedTopics}/${course.totalTopics} topics',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: stuTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${course.syllabusPercent.toStringAsFixed(0)}% Complete',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (course.syllabusPercent / 100.0).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: stuTheme.surfaceTier2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          course.isWarning ? stuTheme.warning : stuTheme.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Divider(color: stuTheme.border, height: 1),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Last lecture: ${course.lastTopic}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: stuTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18, color: stuTheme.textSecondary),
                              color: stuTheme.surfaceTier2,
                              onSelected: (val) {
                                if (val == 'delete') {
                                  _showDeleteCourseDialog(course);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: stuTheme.error, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Delete Subject', style: TextStyle(color: stuTheme.error, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SubjectDetailsScreen(course: course),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: stuTheme.accent,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: stuTheme.accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 1: Attendance Tracker ---
  Widget _buildCollegeAttendanceSection(BuildContext context) {
    final stuTheme = context.stuTheme;
    final now = DateTime.now();
    // Build past 7 days list
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'College Daily Attendance Calendar',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Distinct from subject lectures • Tap date to log campus attendance',
                      style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.calendar_month_rounded, color: stuTheme.accent, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: days.map((date) {
              final status = _repo.getCollegeAttendanceForDate(date);
              final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
              final Color chipColor = status == true
                  ? stuTheme.successContainer
                  : (status == false ? stuTheme.errorContainer : stuTheme.surfaceTier2);
              final Color iconColor = status == true
                  ? stuTheme.success
                  : (status == false ? stuTheme.error : stuTheme.textSecondary);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _showMarkCollegeAttendanceDialog(date),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday ? Border.all(color: stuTheme.accent, width: 1.5) : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stuTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          status == true
                              ? Icons.check_circle_rounded
                              : (status == false ? Icons.cancel_rounded : Icons.radio_button_unchecked),
                          size: 14,
                          color: iconColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAttendanceTrackerSection(BuildContext context) {
    final stuTheme = context.stuTheme;
    final courses = _repo.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Lecture Logger',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: stuTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quick 1-tap logging of present/absent classes per enrolled subject',
          style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = courses[index];
            return CustomCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.code} • ${c.title}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${c.attendedLectures} / ${c.totalLectures} lectures (${c.attendancePercent.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.isWarning ? stuTheme.warning : stuTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.successContainer,
                      foregroundColor: stuTheme.success,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await _repo.logSubjectAttendance(c.code, isPresent: true, slot: 'Lecture');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: stuTheme.surfaceTier3,
                            behavior: SnackBarBehavior.floating,
                            content: Text('+1 Present recorded for ${c.code}', style: TextStyle(color: stuTheme.textPrimary)),
                          ),
                        );
                      }
                    },
                    child: const Text('+ Present', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.errorContainer,
                      foregroundColor: stuTheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await _repo.logSubjectAttendance(c.code, isPresent: false, slot: 'Lecture');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: stuTheme.surfaceTier3,
                            behavior: SnackBarBehavior.floating,
                            content: Text('+1 Absent recorded for ${c.code}', style: TextStyle(color: stuTheme.textPrimary)),
                          ),
                        );
                      }
                    },
                    child: const Text('+ Absent', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceProjectionSection(BuildContext context) {
    final stuTheme = context.stuTheme;
    final safeMissable = _repo.safeMissableClasses;
    final needed = _repo.classesNeededFor75;
    final isSafe = _repo.overallAttendancePercentage >= 75.0;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: stuTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attendance Safety Calculator',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSafe
                ? 'Your overall semester standing is SAFE. Based on currently attended lectures, you can miss up to $safeMissable additional classes without your attendance dropping below the 75% threshold.'
                : 'Your overall attendance is currently BELOW the mandatory 75% requirement. You must attend the next $needed consecutive classes without any absence to recover back above 75%.',
            style: TextStyle(fontSize: 12.5, color: stuTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Syllabus & Units ---
  Widget _buildSyllabusOverviewSection(BuildContext context) {
    final stuTheme = context.stuTheme;
    final courses = _repo.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Syllabus & Topic Tracker',
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
              '${courses.length} Subjects',
              style: TextStyle(fontSize: 12.5, color: stuTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...courses.map((course) {
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.accent,
                            ),
                          ),
                          Text(
                            course.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${course.syllabusPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (course.syllabusPercent / 100.0).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: stuTheme.surfaceTier2,
                    valueColor: AlwaysStoppedAnimation<Color>(stuTheme.accent),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: stuTheme.border, height: 1),
                const SizedBox(height: 8),

                // Units List
                ...course.units.map((unit) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit ${unit.unitNumber}: ${unit.title}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...unit.topics.map((topic) {
                          return InkWell(
                            onTap: () {
                              _repo.toggleTopicCompletion(course.code, unit.unitNumber, topic.id);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    topic.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 16,
                                    color: topic.isCompleted ? stuTheme.success : stuTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      topic.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: topic.isCompleted ? stuTheme.textSecondary : stuTheme.textPrimary,
                                        decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
