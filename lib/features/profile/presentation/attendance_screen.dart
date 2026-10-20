import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  String? _selectedCourseCode;

  void _showMarkAttendanceDialog(Course course) {
    final stuTheme = context.stuTheme;
    final topicCtrl = TextEditingController();

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
              'Log Attendance for ${course.code}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              course.title,
              style: TextStyle(fontSize: 13, color: stuTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: topicCtrl,
              style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Lecture Topic / Chapter (Optional)',
                hintText: 'e.g. Dynamic Programming or Lab 3',
                filled: true,
                fillColor: stuTheme.surfaceTier2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Present', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await _repo.logSubjectAttendance(
                        course.code,
                        isPresent: true,
                        topic: topicCtrl.text.trim().isNotEmpty ? topicCtrl.text.trim() : null,
                      );
                      if (context.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: stuTheme.error,
                      side: BorderSide(color: stuTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Absent', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await _repo.logSubjectAttendance(
                        course.code,
                        isPresent: false,
                        topic: topicCtrl.text.trim().isNotEmpty ? topicCtrl.text.trim() : null,
                      );
                      if (context.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
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
        final courses = _repo.courses;
        final selectedCode = _selectedCourseCode ?? (courses.isNotEmpty ? courses.first.code : null);
        final history = selectedCode != null ? _repo.getAttendanceHistoryForSubject(selectedCode) : <SubjectAttendanceRecord>[];

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
              'My Attendance',
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
                      // Overview Banner (Counts only - NO percentages!)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: stuTheme.surfaceTier1,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: stuTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Attendance Record',
                              style: TextStyle(fontSize: 13, color: stuTheme.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _repo.attendanceSummaryHeadline,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: stuTheme.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _repo.attendanceSummaryDetail,
                              style: TextStyle(fontSize: 13, color: stuTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Enrolled Subjects',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      if (courses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: stuTheme.surfaceTier1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: stuTheme.border),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.school_outlined, size: 32, color: stuTheme.textMuted),
                              const SizedBox(height: 10),
                              Text(
                                'No subjects registered',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add a subject from the Academics tab to start tracking your attendance.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: stuTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Subjects list
                        ...courses.map((c) {
                          final isSelected = c.code == selectedCode;
                          final attended = c.attendedLectures;
                          final total = c.totalLectures;
                          final missed = (total - attended).clamp(0, 9999);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() => _selectedCourseCode = c.code),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? stuTheme.accent.withValues(alpha: 0.1)
                                      : stuTheme.surfaceTier1,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? stuTheme.accent : stuTheme.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.title,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: stuTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            total == 0
                                                ? '${c.code} • No classes recorded'
                                                : '${c.code} • $attended attended, $missed absent ($total total)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: stuTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: stuTheme.accent,
                                        foregroundColor: stuTheme.onAccent,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showMarkAttendanceDialog(c),
                                      child: const Text('Mark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 24),

                      // Historical Attendance Records for selected subject
                      if (selectedCode != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$selectedCode Attendance History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                            ),
                            if (history.isNotEmpty)
                              Text(
                                '${history.length} records',
                                style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (history.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: stuTheme.surfaceTier1,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: stuTheme.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'No attendance history recorded yet for $selectedCode.',
                              style: TextStyle(fontSize: 13, color: stuTheme.textMuted),
                            ),
                          )
                        else
                          ...history.map((rec) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
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
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: (rec.isPresent ? stuTheme.success : stuTheme.error).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        rec.isPresent ? Icons.check_rounded : Icons.close_rounded,
                                        color: rec.isPresent ? stuTheme.success : stuTheme.error,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rec.isPresent ? 'Attended Lecture' : 'Absence Recorded',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: stuTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('EEE, MMM d, yyyy').format(rec.date) +
                                                (rec.topicDiscussed != null ? ' • ${rec.topicDiscussed}' : ''),
                                            style: TextStyle(fontSize: 11.5, color: stuTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Correction toggle button
                                    TextButton(
                                      onPressed: () => _repo.correctSubjectAttendanceRecord(rec.id, !rec.isPresent),
                                      child: Text(
                                        rec.isPresent ? 'Change to Absent' : 'Change to Present',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: stuTheme.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
}
