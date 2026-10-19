import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/pill_badge.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Course? course;

  const SubjectDetailsScreen({
    super.key,
    this.course,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  int _selectedTabIndex = 0; // 0: Syllabus & Units, 1: Attendance, 2: Docs (8), 3: Tasks (3)
  int _selectedFilterIndex = 0;
  bool _isBookmarked = true;
  bool _unit1Expanded = false;
  bool _unit2Expanded = true;
  bool _unit3Expanded = false;

  final List<String> _tabs = [
    'Syllabus & Units',
    'Attendance',
    'Docs (8)',
    'Tasks (3)',
  ];

  final List<String> _unitFilters = [
    'All Units',
    'Completed (1)',
    'In Progress (1)',
    'Upcoming (1)',
  ];

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final course = widget.course ?? SampleData.courses.first;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppBar(
        backgroundColor: stuTheme.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 48,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: stuTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: stuTheme.surfaceTier2,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: stuTheme.border),
          ),
          child: Text(
            course.code,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: stuTheme.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isBookmarked ? stuTheme.accent : stuTheme.textSecondary,
              size: 24,
            ),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
            },
          ),
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: stuTheme.textSecondary, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Hero Subject Header Card
            _buildHeroCourseCard(context, course),

            const SizedBox(height: 16),

            // 3. Segmented Navigation Tabs
            _buildSegmentedTabs(context),

            const SizedBox(height: 16),

            // 4. Search & Filter Bar
            _buildSearchAndFilters(context),

            const SizedBox(height: 14),

            // 5. Units Breakdown Stack
            _buildUnitsStack(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCourseCard(BuildContext context, Course course) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: PillBadge(
                  label: '${course.code} • ${course.credits} Credits • Core',
                  icon: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: stuTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  backgroundColor: stuTheme.surfaceTier2,
                  textColor: stuTheme.textSecondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Fall 2024',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Course Title
          Text(
            course.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: stuTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          // Instructor & Location
          Row(
            children: [
              Icon(Icons.person_rounded, size: 14, color: stuTheme.accent),
              const SizedBox(width: 4),
              Text(
                course.professor,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text('•', style: TextStyle(color: stuTheme.textMuted)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  course.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: stuTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${course.schedule} • ${course.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: stuTheme.border, height: 1),
          const SizedBox(height: 14),

          // 3 Bento Status Tiles
          Row(
            children: [
              // Attendance
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Attendance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: stuTheme.textSecondary),
                            ),
                          ),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: stuTheme.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.attendancePercent.toInt()}%',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.success,
                        ),
                      ),
                      Text(
                        '${course.attendedLectures}/${course.totalLectures} classes',
                        style: TextStyle(fontSize: 10, color: stuTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Syllabus
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Syllabus',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: stuTheme.textSecondary),
                            ),
                          ),
                          Icon(
                            Icons.pie_chart_rounded,
                            size: 13,
                            color: stuTheme.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.syllabusPercent.toInt()}%',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${course.completedTopics}/${course.totalTopics} topics',
                        style: TextStyle(fontSize: 10, color: stuTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Standing
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Standing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: stuTheme.textSecondary),
                            ),
                          ),
                          Icon(
                            Icons.grade_rounded,
                            size: 13,
                            color: stuTheme.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.grade,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        course.standing,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: stuTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? stuTheme.surfaceTier1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
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
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildSearchAndFilters(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: stuTheme.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: stuTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search topics or concepts...',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stuTheme.border),
              ),
              child: Icon(Icons.tune_rounded, size: 18, color: stuTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_unitFilters.length, (index) {
              final isSelected = _selectedFilterIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? stuTheme.accent : stuTheme.surfaceTier2,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSelected ? stuTheme.accent : stuTheme.border,
                      ),
                    ),
                    child: Text(
                      _unitFilters[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? stuTheme.onAccent : stuTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitsStack(BuildContext context) {
    final units = SampleData.cs201Units;

    return Column(
      children: [
        // Unit 1 (Completed)
        _buildUnit1Card(context, units[0]),

        const SizedBox(height: 12),

        // Unit 2 (Current Focus & In Progress)
        _buildUnit2Card(context, units[1]),

        const SizedBox(height: 12),

        // Unit 3 (Upcoming)
        _buildUnit3Card(context, units[2]),
      ],
    );
  }

  Widget _buildUnit1Card(BuildContext context, CourseUnit unit) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _unit1Expanded = !_unit1Expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: stuTheme.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.done_all_rounded,
                    color: stuTheme.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit 1: ${unit.title}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Completed • 4 of 4 topics mastered',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: stuTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _unit1Expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: stuTheme.textSecondary,
                ),
              ],
            ),
          ),
          if (_unit1Expanded) ...[
            const SizedBox(height: 12),
            Divider(color: stuTheme.border, height: 1),
            const SizedBox(height: 10),
            ...unit.topics.map((t) => _buildTopicRow(context, t)),
          ],
        ],
      ),
    );
  }

  Widget _buildUnit2Card(BuildContext context, CourseUnit unit) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      borderColor: stuTheme.accent.withValues(alpha: 0.5),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: PillBadge(
                  label: 'Unit 2 • Ongoing',
                  backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
                  textColor: stuTheme.accent,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(width: 6),
              PillBadge(
                label: 'Current Focus',
                backgroundColor: stuTheme.accent,
                textColor: stuTheme.onAccent,
                fontSize: 10.5,
              ),
            ],
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () => setState(() => _unit2Expanded = !_unit2Expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '4 of 6 topics completed • 66%',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _unit2Expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: stuTheme.textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.66,
              minHeight: 5,
              backgroundColor: stuTheme.surfaceTier2,
              valueColor: AlwaysStoppedAnimation<Color>(stuTheme.accent),
            ),
          ),

          if (_unit2Expanded) ...[
            const SizedBox(height: 12),
            ...unit.topics.map((t) => _buildTopicRow(context, t)),
          ],
        ],
      ),
    );
  }

  Widget _buildUnit3Card(BuildContext context, CourseUnit unit) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _unit3Expanded = !_unit3Expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: stuTheme.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit 3: ${unit.title}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upcoming • 0 of 5 topics',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: stuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _unit3Expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: stuTheme.textSecondary,
                ),
              ],
            ),
          ),
          if (_unit3Expanded) ...[
            const SizedBox(height: 12),
            Divider(color: stuTheme.border, height: 1),
            const SizedBox(height: 10),
            ...unit.topics.map((t) => _buildTopicRow(context, t)),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicRow(BuildContext context, UnitTopic topic) {
    final stuTheme = context.stuTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stuTheme.surfaceTier2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: topic.isCompleted ? stuTheme.success : Colors.transparent,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: topic.isCompleted ? stuTheme.success : stuTheme.border,
              ),
            ),
            child: topic.isCompleted
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      topic.date,
                      style: TextStyle(fontSize: 10.5, color: stuTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  topic.subtitle,
                  style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
