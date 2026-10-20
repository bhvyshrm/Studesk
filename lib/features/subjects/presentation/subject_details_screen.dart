import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
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
  final StuDeskRepository _repo = StuDeskRepository.instance;
  int _selectedTabIndex = 0; // 0: Syllabus & Units, 1: Attendance, 2: Docs, 3: Tasks
  bool _isBookmarked = true;
  final Set<int> _expandedUnits = {1, 2};

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
          'Are you sure you want to delete ${course.title} (${course.code})?',
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
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.deleteCourse(course.code);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        Course course;
        if (widget.course != null) {
          course = _repo.courses.firstWhere(
            (c) => c.code == widget.course!.code,
            orElse: () => widget.course!,
          );
        } else if (_repo.courses.isNotEmpty) {
          course = _repo.courses.first;
        } else {
          return Scaffold(
            backgroundColor: stuTheme.canvas,
            appBar: AppBar(backgroundColor: stuTheme.canvas),
            body: Center(
              child: Text('Subject not found', style: TextStyle(color: stuTheme.textSecondary)),
            ),
          );
        }

        final subjectResources = _repo.resources
            .where((r) => r.subjectTag.toLowerCase().contains(course.code.toLowerCase()))
            .toList();
        final subjectTasks = _repo.tasks
            .where((t) => t.categoryTag.toLowerCase().contains(course.code.toLowerCase()))
            .toList();
        final subjectAttendance = _repo.subjectAttendance
            .where((a) => a.courseCode.toLowerCase() == course.code.toLowerCase())
            .toList();

        final tabs = [
          'Syllabus & Units',
          'Attendance',
          'Docs (${subjectResources.length})',
          'Tasks (${subjectTasks.length})',
        ];

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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: stuTheme.textSecondary, size: 22),
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
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Subject Header Card
                _buildHeroCourseCard(context, course),

                const SizedBox(height: 16),

                // 2. Segmented Navigation Tabs
                _buildSegmentedTabs(context, tabs),

                const SizedBox(height: 16),

                // 3. Tab Contents
                if (_selectedTabIndex == 0) ...[
                  _buildUnitsStack(context, course),
                ] else if (_selectedTabIndex == 1) ...[
                  _buildAttendanceTab(context, course, subjectAttendance),
                ] else if (_selectedTabIndex == 2) ...[
                  _buildDocsTab(context, subjectResources),
                ] else ...[
                  _buildTasksTab(context, course, subjectTasks),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCourseCard(BuildContext context, Course course) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  'Fall Semester',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

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
                            course.isWarning ? Icons.warning_rounded : Icons.check_circle_rounded,
                            size: 13,
                            color: course.isWarning ? stuTheme.warning : stuTheme.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.attendedLectures} Attended',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: course.isWarning ? stuTheme.warning : stuTheme.success,
                        ),
                      ),
                      Text(
                        '${course.totalLectures} lectures held',
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
                            Icons.menu_book_rounded,
                            size: 13,
                            color: stuTheme.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.completedTopics} Done',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        course.totalTopics > course.completedTopics
                            ? '${course.totalTopics - course.completedTopics} topics left'
                            : 'All caught up',
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

  Widget _buildSegmentedTabs(BuildContext context, List<String> tabs) {
    final stuTheme = context.stuTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: stuTheme.surfaceTier2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stuTheme.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
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
                  tabs[index],
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

  Widget _buildUnitsStack(BuildContext context, Course course) {
    final stuTheme = context.stuTheme;

    if (course.units.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No syllabus units added yet.',
            style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: course.units.map((unit) {
        final isExpanded = _expandedUnits.contains(unit.unitNumber);
        final completedInUnit = unit.topics.where((t) => t.isCompleted).length;
        final totalInUnit = unit.topics.length;

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedUnits.remove(unit.unitNumber);
                    } else {
                      _expandedUnits.add(unit.unitNumber);
                    }
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: completedInUnit == totalInUnit && totalInUnit > 0
                            ? stuTheme.successContainer
                            : stuTheme.surfaceTier2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completedInUnit == totalInUnit && totalInUnit > 0
                            ? Icons.done_all_rounded
                            : Icons.auto_stories_rounded,
                        color: completedInUnit == totalInUnit && totalInUnit > 0
                            ? stuTheme.success
                            : stuTheme.accent,
                        size: 18,
                      ),
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
                                  unit.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: stuTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (unit.status == UnitStatus.current) ...[
                                const SizedBox(width: 8),
                                PillBadge(
                                  label: 'Current Focus',
                                  backgroundColor: stuTheme.accent,
                                  textColor: stuTheme.onAccent,
                                  fontSize: 10.5,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unit ${unit.unitNumber} • $completedInUnit of $totalInUnit topics completed',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: stuTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Divider(color: stuTheme.border, height: 1),
                const SizedBox(height: 10),
                ...unit.topics.map((t) => _buildTopicRow(context, course.code, unit.unitNumber, t)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopicRow(BuildContext context, String courseCode, int unitNumber, UnitTopic topic) {
    final stuTheme = context.stuTheme;

    return InkWell(
      onTap: () {
        _repo.toggleTopicCompletion(courseCode, unitNumber, topic.id);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
                            color: topic.isCompleted ? stuTheme.textSecondary : stuTheme.textPrimary,
                            decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
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
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context, Course course, List<SubjectAttendanceRecord> records) {
    final stuTheme = context.stuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recorded Lectures for ${course.code}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stuTheme.successContainer,
                    foregroundColor: stuTheme.success,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await _repo.logSubjectAttendance(course.code, isPresent: true, slot: 'Lecture');
                  },
                  child: const Text('+ Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stuTheme.errorContainer,
                    foregroundColor: stuTheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await _repo.logSubjectAttendance(course.code, isPresent: false, slot: 'Lecture');
                  },
                  child: const Text('+ Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (records.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No recorded lecture logs for ${course.code} yet.',
                style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final rec = records[records.length - 1 - index];
              return CustomCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      rec.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: rec.isPresent ? stuTheme.success : stuTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.topicDiscussed ?? 'Lecture Session',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                          ),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(rec.date),
                            style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PillBadge(
                      label: rec.isPresent ? 'Attended' : 'Absent',
                      backgroundColor: rec.isPresent ? stuTheme.successContainer : stuTheme.errorContainer,
                      textColor: rec.isPresent ? stuTheme.success : stuTheme.error,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDocsTab(BuildContext context, List<LibraryResource> resources) {
    final stuTheme = context.stuTheme;

    if (resources.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No documents or notes tagged for this subject.',
            style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: resources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final res = resources[index];
        return CustomCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                res.type == ResourceType.video ? Icons.play_circle_rounded : Icons.description_rounded,
                color: stuTheme.accent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.title,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                    ),
                    Text(
                      res.channel ?? 'Study Resource',
                      style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (res.duration != null)
                PillBadge(
                  label: res.duration!,
                  backgroundColor: stuTheme.surfaceTier2,
                  textColor: stuTheme.textSecondary,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(BuildContext context, Course course, List<TaskItem> tasks) {
    final stuTheme = context.stuTheme;

    if (tasks.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No assignments or tasks assigned to ${course.code}.',
            style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final task = tasks[index];
        return CustomCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: task.isCompleted ? stuTheme.success : stuTheme.border,
                ),
                onPressed: () => _repo.toggleTask(task.id),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: task.isCompleted ? stuTheme.textSecondary : stuTheme.textPrimary,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (task.dueTime != null)
                Text(
                  task.dueTime!,
                  style: TextStyle(fontSize: 11, color: stuTheme.error, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        );
      },
    );
  }
}
