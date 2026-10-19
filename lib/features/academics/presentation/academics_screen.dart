import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/sample_data.dart';
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
  int _selectedTab = 0; // 0: Overview & Subjects, 1: Attendance Tracker, 2: Syllabus & Units
  int _selectedDayIndex = 2; // Wednesday 23

  final List<String> _tabs = [
    'Overview & Subjects',
    'Attendance Tracker',
    'Syllabus & Units',
  ];

  final List<Map<String, String>> _weekDays = [
    {'day': 'M', 'date': '21'},
    {'day': 'T', 'date': '22'},
    {'day': 'W', 'date': '23'},
    {'day': 'Th', 'date': '24'},
    {'day': 'F', 'date': '25'},
  ];

  void _showMarkTodayDialog() {
    final stuTheme = context.stuTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            _buildDialogLectureOption('CS201 Data Structures (09:30 AM)', true),
            const SizedBox(height: 8),
            _buildDialogLectureOption('CS204 Operating Systems (11:15 AM)', false),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: stuTheme.surfaceTier3,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Attendance updated to 87.1% (143/165 lectures)',
                    style: TextStyle(color: stuTheme.textPrimary),
                  ),
                ),
              );
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogLectureOption(String label, bool isSelected) {
    final stuTheme = context.stuTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? stuTheme.accent.withValues(alpha: 0.15) : stuTheme.surfaceTier2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? stuTheme.accent : stuTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isSelected ? stuTheme.accent : stuTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: stuTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppTopBar(
        title: 'Academics',
        titleTrailing: PillBadge(
          label: 'Sem 5',
          backgroundColor: stuTheme.accent.withValues(alpha: 0.18),
          textColor: stuTheme.accent,
        ),
        subtitle: 'Fall Semester 2024 • B.Tech CSE',
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

            // Overall Attendance KPI Card
            _buildAttendanceKPICard(context),

            const SizedBox(height: 20),

            // Weekly Schedule Strip & Today's lectures
            _buildWeeklyScheduleStrip(context),

            const SizedBox(height: 20),

            // Registered Courses Section
            _buildRegisteredCourses(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
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
                            color: stuTheme.success,
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
                            '86.4%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: stuTheme.textPrimary,
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
                        text: '142 ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: 'of 164 total lectures completed',
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
                widthFactor: 0.864,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: stuTheme.accent,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              // 75% Threshold indicator marker
              Positioned(
                left: MediaQuery.of(context).size.width * 0.75 - 32,
                top: -2,
                bottom: -2,
                child: Container(
                  width: 2,
                  color: stuTheme.textSecondary.withValues(alpha: 0.5),
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
                  color: stuTheme.success,
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
                    color: stuTheme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 18,
                    color: stuTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You can safely miss up to 3 classes while maintaining >75% target',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Projection based on 28 remaining scheduled lectures before semester end exams.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Today's Schedule",
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
                'Full Week',
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

        // Day Selector Pill Strip
        Row(
          children: List.generate(_weekDays.length, (index) {
            final item = _weekDays[index];
            final isSelected = _selectedDayIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < _weekDays.length - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDayIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? stuTheme.accent : stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? stuTheme.accent : stuTheme.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: stuTheme.accent.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          item['day']!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? stuTheme.onAccent : stuTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['date']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? stuTheme.onAccent : stuTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        // Today's Lectures Mini List
        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 38,
                decoration: BoxDecoration(
                  color: stuTheme.success,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Structures & Algorithms',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '09:30 - 10:45 AM • Room 402B',
                      style: TextStyle(
                        fontSize: 12,
                        color: stuTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PillBadge(
                label: 'Attended',
                icon: Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: stuTheme.success,
                ),
                backgroundColor: stuTheme.successContainer,
                textColor: stuTheme.success,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 38,
                decoration: BoxDecoration(
                  color: stuTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operating Systems',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '11:15 AM - 12:30 PM • CS Lab 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: stuTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PillBadge(
                label: 'Live Now',
                backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
                textColor: stuTheme.accent,
                borderColor: stuTheme.accent.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Break Notification Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: stuTheme.surfaceTier2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.coffee_rounded,
                      size: 15,
                      color: stuTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Lunch & Mentorship Break',
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
              const SizedBox(width: 8),
              Text(
                '12:30 - 01:30 PM',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: stuTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredCourses(BuildContext context) {
    final stuTheme = context.stuTheme;
    final courses = SampleData.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
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
              '4 Enrolled',
              style: TextStyle(
                fontSize: 12.5,
                color: stuTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

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
                                    label: 'On the edge',
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
                            '${course.attendancePercent.toInt()}%',
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
                        '${course.syllabusPercent.toInt()}% Complete',
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
                      value: course.syllabusPercent / 100.0,
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
                          'Last class: ${course.lastTopic}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: stuTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
            );
          },
        ),
      ],
    );
  }
}
