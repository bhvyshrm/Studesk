import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/data/sample_data.dart';
import '../../shared/models/models.dart';

/// Central repository managing offline-first persistence and state for StuDesk.
class StuDeskRepository extends ChangeNotifier {
  StuDeskRepository._();
  static final StuDeskRepository instance = StuDeskRepository._();

  static const String _prefProfile = 'studesk_profile';
  static const String _prefCourses = 'studesk_courses';
  static const String _prefTasks = 'studesk_tasks';
  static const String _prefResources = 'studesk_resources';
  static const String _prefJournals = 'studesk_journals';
  static const String _prefSubjectAttendance = 'studesk_subject_attendance';
  static const String _prefCollegeAttendance = 'studesk_college_attendance';
  static const String _prefTimetable = 'studesk_timetable';
  static const String _prefExams = 'studesk_exams';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  UserProfile _profile = UserProfile.defaultProfile();
  List<Course> _courses = List.from(SampleData.courses);
  List<TaskItem> _tasks = SampleData.getInitialTasks();
  List<LibraryResource> _resources = List.from(SampleData.libraryResources);
  List<JournalEntry> _journals = [];
  List<SubjectAttendanceRecord> _subjectAttendance = [];
  List<CollegeAttendanceRecord> _collegeAttendance = [];
  List<TimetableEntry> _timetable = const [
    TimetableEntry(
      id: 'tt-1',
      dayOfWeek: 1, // Mon
      startTime: '10:15',
      endTime: '11:45',
      courseCode: 'CS201',
      title: 'Data Structures & Algorithms',
      room: 'Hall B-204',
      professor: 'Dr. Vance',
    ),
    TimetableEntry(
      id: 'tt-2',
      dayOfWeek: 2, // Tue
      startTime: '11:15',
      endTime: '12:30',
      courseCode: 'CS204',
      title: 'Operating Systems',
      room: 'CS Lab 2',
      professor: 'Prof. Helen',
    ),
    TimetableEntry(
      id: 'tt-3',
      dayOfWeek: 3, // Wed
      startTime: '10:15',
      endTime: '11:45',
      courseCode: 'CS201',
      title: 'Data Structures & Algorithms',
      room: 'Hall B-204',
      professor: 'Dr. Vance',
    ),
    TimetableEntry(
      id: 'tt-4',
      dayOfWeek: 4, // Thu
      startTime: '11:15',
      endTime: '12:30',
      courseCode: 'CS204',
      title: 'Operating Systems',
      room: 'CS Lab 2',
      professor: 'Prof. Helen',
    ),
  ];
  List<ExamItem> _exams = [
    ExamItem(
      id: 'exam-1',
      courseCode: 'CS201',
      title: 'Midterm Exam: Trees & Graphs',
      examDate: DateTime.now().add(const Duration(days: 12)),
      room: 'Auditorium A',
      syllabusCutoff: 'Units 1 - 3',
      weightagePercent: 30,
    ),
  ];

  // Getters
  UserProfile get profile => _profile;
  List<Course> get courses => List.unmodifiable(_courses);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<LibraryResource> get resources => List.unmodifiable(_resources);
  List<JournalEntry> get journals => List.unmodifiable(_journals);
  List<SubjectAttendanceRecord> get subjectAttendance => List.unmodifiable(_subjectAttendance);
  List<CollegeAttendanceRecord> get collegeAttendance => List.unmodifiable(_collegeAttendance);
  List<TimetableEntry> get timetable => List.unmodifiable(_timetable);
  List<ExamItem> get exams => List.unmodifiable(_exams);

  // --- Attendance Analytics ---
  int get totalAttendedLectures => _courses.fold(0, (acc, c) => acc + c.attendedLectures);
  int get totalLectures => _courses.fold(0, (acc, c) => acc + c.totalLectures);

  double get overallAttendancePercentage {
    final total = totalLectures;
    if (total == 0) return 100.0;
    return (totalAttendedLectures / total) * 100.0;
  }

  /// Calculates how many classes can be safely missed while staying >= 75% target,
  /// or how many consecutive classes must be attended if currently below 75%.
  int get safeMissableClasses {
    final attended = totalAttendedLectures;
    final total = totalLectures;
    if (total == 0) return 0;
    final diff = attended - (0.75 * total);
    if (diff <= 0) return 0;
    return (diff / 0.75).floor();
  }

  int get classesNeededFor75 {
    final attended = totalAttendedLectures;
    final total = totalLectures;
    if (total == 0) return 0;
    if (overallAttendancePercentage >= 75.0) return 0;
    final needed = (0.75 * total - attended) / 0.25;
    return needed.ceil();
  }

  // --- Task Analytics ---
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => _tasks.length;

  // --- Exam Analytics ---
  ExamItem? get nextUpcomingExam {
    if (_exams.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _exams.where((e) {
      final examDay = DateTime(e.examDate.year, e.examDate.month, e.examDate.day);
      return !examDay.isBefore(today);
    }).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.examDate.compareTo(b.examDate));
    return upcoming.first;
  }

  // --- Timetable & Lecture Helpers ---
  List<TimetableEntry> getTimetableForDay(int dayOfWeek) {
    return _timetable.where((t) => t.dayOfWeek == dayOfWeek).toList();
  }

  TimetableEntry? get nextOrCurrentTimetableEntry {
    final weekday = DateTime.now().weekday;
    final todayEntries = getTimetableForDay(weekday);
    if (todayEntries.isNotEmpty) return todayEntries.first;
    if (_timetable.isNotEmpty) return _timetable.first;
    return null;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Profile
      final profileStr = prefs.getString(_prefProfile);
      if (profileStr != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileStr) as Map<String, dynamic>);
      }

      // Load Courses
      final coursesStr = prefs.getString(_prefCourses);
      if (coursesStr != null) {
        final list = jsonDecode(coursesStr) as List<dynamic>;
        _courses = list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _courses = List.from(SampleData.courses);
        _saveCourses();
      }

      // Load Tasks
      final tasksStr = prefs.getString(_prefTasks);
      if (tasksStr != null) {
        final list = jsonDecode(tasksStr) as List<dynamic>;
        _tasks = list.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _tasks = SampleData.getInitialTasks();
        _saveTasks();
      }

      // Load Resources
      final resourcesStr = prefs.getString(_prefResources);
      if (resourcesStr != null) {
        final list = jsonDecode(resourcesStr) as List<dynamic>;
        _resources = list.map((e) => LibraryResource.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _resources = List.from(SampleData.libraryResources);
        _saveResources();
      }

      // Load Journals
      final journalsStr = prefs.getString(_prefJournals);
      if (journalsStr != null) {
        final list = jsonDecode(journalsStr) as List<dynamic>;
        _journals = list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _journals = [
          JournalEntry(
            id: 'jrn-init',
            date: DateTime.now(),
            mood: 'Deep Focus',
            streak: '14 Days',
            tasksCompleted: 4,
            totalTasks: 5,
            linkedCourses: const ['CS201', 'CS204'],
            learnedText:
                'Solid grasp on binary search tree rebalancing and Red-Black tree rotations in CS201. Reviewed kernel synchronization in CS204.',
            accomplishments: const [
              'Finished OS Lab 4 kernel sync schema draft.',
              '30-min LeetCode practice completed.',
            ],
            tags: const ['Algorithms', 'Systems', 'Daily'],
            wordCount: 142,
          ),
        ];
        _saveJournals();
      }

      // Load Subject Attendance
      final subAttStr = prefs.getString(_prefSubjectAttendance);
      if (subAttStr != null) {
        final list = jsonDecode(subAttStr) as List<dynamic>;
        _subjectAttendance = list
            .map((e) => SubjectAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load College Attendance
      final colAttStr = prefs.getString(_prefCollegeAttendance);
      if (colAttStr != null) {
        final list = jsonDecode(colAttStr) as List<dynamic>;
        _collegeAttendance = list
            .map((e) => CollegeAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final today = DateTime.now();
        _collegeAttendance = [
          CollegeAttendanceRecord(
            id: 'col-init-1',
            date: today.subtract(const Duration(days: 2)),
            isPresent: true,
            remarks: 'Present all lectures',
          ),
          CollegeAttendanceRecord(
            id: 'col-init-2',
            date: today.subtract(const Duration(days: 1)),
            isPresent: true,
            remarks: 'Present all lectures',
          ),
          CollegeAttendanceRecord(
            id: 'col-init-3',
            date: today,
            isPresent: true,
            remarks: 'On campus',
          ),
        ];
        _saveCollegeAttendance();
      }

      // Load Timetable
      final timetableStr = prefs.getString(_prefTimetable);
      if (timetableStr != null) {
        final list = jsonDecode(timetableStr) as List<dynamic>;
        _timetable = list.map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _timetable = [
          const TimetableEntry(
            id: 'tt-1',
            dayOfWeek: 1, // Mon
            startTime: '10:15',
            endTime: '11:45',
            courseCode: 'CS201',
            title: 'Data Structures & Algorithms',
            room: 'Hall B-204',
            professor: 'Dr. Vance',
          ),
          const TimetableEntry(
            id: 'tt-2',
            dayOfWeek: 2, // Tue
            startTime: '11:15',
            endTime: '12:30',
            courseCode: 'CS204',
            title: 'Operating Systems',
            room: 'CS Lab 2',
            professor: 'Prof. Helen',
          ),
          const TimetableEntry(
            id: 'tt-3',
            dayOfWeek: 3, // Wed
            startTime: '10:15',
            endTime: '11:45',
            courseCode: 'CS201',
            title: 'Data Structures & Algorithms',
            room: 'Hall B-204',
            professor: 'Dr. Vance',
          ),
          const TimetableEntry(
            id: 'tt-4',
            dayOfWeek: 4, // Thu
            startTime: '11:15',
            endTime: '12:30',
            courseCode: 'CS204',
            title: 'Operating Systems',
            room: 'CS Lab 2',
            professor: 'Prof. Helen',
          ),
        ];
        _saveTimetable();
      }

      // Load Exams
      final examsStr = prefs.getString(_prefExams);
      if (examsStr != null) {
        final list = jsonDecode(examsStr) as List<dynamic>;
        _exams = list.map((e) => ExamItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        final now = DateTime.now();
        _exams = [
          ExamItem(
            id: 'exam-1',
            courseCode: 'CS201',
            title: 'Midterm Exam: Trees & Graphs',
            examDate: now.add(const Duration(days: 12)),
            room: 'Auditorium A',
            syllabusCutoff: 'Units 1 - 3',
            weightagePercent: 30,
          ),
          ExamItem(
            id: 'exam-2',
            courseCode: 'CS204',
            title: 'Operating Systems Lab Practical',
            examDate: now.add(const Duration(days: 20)),
            room: 'Systems Lab 1',
            syllabusCutoff: 'Process Synchronization & Memory',
            weightagePercent: 20,
          ),
        ];
        _saveExams();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('StuDeskRepository initialization error: $e');
      _courses = List.from(SampleData.courses);
      _tasks = SampleData.getInitialTasks();
      _resources = List.from(SampleData.libraryResources);
      _isInitialized = true;
      notifyListeners();
    }
  }

  // --- Profile Methods ---
  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProfile, jsonEncode(_profile.toJson()));
  }

  // --- Course & Syllabus Methods ---
  Future<void> addCourse(Course course) async {
    _courses.add(course);
    notifyListeners();
    await _saveCourses();
  }

  Future<void> updateCourse(Course updatedCourse) async {
    final index = _courses.indexWhere((c) => c.code == updatedCourse.code);
    if (index != -1) {
      _courses[index] = updatedCourse;
      notifyListeners();
      await _saveCourses();
    }
  }

  Future<void> deleteCourse(String code) async {
    _courses.removeWhere((c) => c.code == code);
    notifyListeners();
    await _saveCourses();
  }

  Future<void> toggleTopicCompletion(String courseCode, int unitNumber, String topicId) async {
    final cIndex = _courses.indexWhere((c) => c.code == courseCode);
    if (cIndex == -1) return;

    final course = _courses[cIndex];
    final updatedUnits = course.units.map((unit) {
      if (unit.unitNumber != unitNumber) return unit;
      final updatedTopics = unit.topics.map((topic) {
        if (topic.id != topicId) return topic;
        return topic.copyWith(isCompleted: !topic.isCompleted);
      }).toList();
      return unit.copyWith(topics: updatedTopics);
    }).toList();

    _courses[cIndex] = course.copyWith(units: updatedUnits);
    notifyListeners();
    await _saveCourses();
  }

  Future<void> logSubjectAttendance(
    String courseCode, {
    required bool isPresent,
    String? slot,
    String? topic,
  }) async {
    final record = SubjectAttendanceRecord(
      id: 'sub_${DateTime.now().microsecondsSinceEpoch}',
      courseCode: courseCode,
      date: DateTime.now(),
      isPresent: isPresent,
      lectureSlot: slot,
      topicDiscussed: topic,
    );
    _subjectAttendance.add(record);

    final cIndex = _courses.indexWhere((c) => c.code == courseCode);
    if (cIndex != -1) {
      final course = _courses[cIndex];
      final newAttended = isPresent ? course.attendedLectures + 1 : course.attendedLectures;
      final newTotal = course.totalLectures + 1;
      _courses[cIndex] = course.copyWith(
        attendedLectures: newAttended,
        totalLectures: newTotal,
      );
      await _saveCourses();
    }

    notifyListeners();
    await _saveSubjectAttendance();
  }

  // --- College Daily Attendance Calendar Methods ---
  Future<void> logCollegeAttendance(DateTime date, bool isPresent, {String? remarks}) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final existingIndex = _collegeAttendance.indexWhere((r) =>
        r.date.year == targetDate.year &&
        r.date.month == targetDate.month &&
        r.date.day == targetDate.day);

    if (existingIndex != -1) {
      _collegeAttendance[existingIndex] = _collegeAttendance[existingIndex].copyWith(
        isPresent: isPresent,
        remarks: remarks,
      );
    } else {
      _collegeAttendance.add(CollegeAttendanceRecord(
        id: 'col_${DateTime.now().microsecondsSinceEpoch}',
        date: targetDate,
        isPresent: isPresent,
        remarks: remarks,
      ));
    }

    notifyListeners();
    await _saveCollegeAttendance();
  }

  bool? getCollegeAttendanceForDate(DateTime date) {
    final match = _collegeAttendance.cast<CollegeAttendanceRecord?>().firstWhere(
          (r) =>
              r != null &&
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
          orElse: () => null,
        );
    return match?.isPresent;
  }

  // --- Task Methods ---
  Future<void> addTask(TaskItem task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _saveTasks();
  }

  // --- Library Resource & Note Methods ---
  Future<void> addResource(LibraryResource resource) async {
    _resources.insert(0, resource);
    notifyListeners();
    await _saveResources();
  }

  Future<void> toggleResourceBookmark(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index != -1) {
      final current = _resources[index];
      _resources[index] = current.copyWith(isBookmarked: !current.isBookmarked);
      notifyListeners();
      await _saveResources();
    }
  }

  Future<void> deleteResource(String resourceId) async {
    _resources.removeWhere((r) => r.id == resourceId);
    notifyListeners();
    await _saveResources();
  }

  // --- Journal & Streaks Methods ---
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final index = _journals.indexWhere((j) => j.id == entry.id);
    if (index != -1) {
      _journals[index] = entry;
    } else {
      _journals.insert(0, entry);
    }

    // Update streak in profile
    final currentStreak = calculateStreak();
    _profile = _profile.copyWith(streakDays: currentStreak, lastActiveDate: DateTime.now());
    await updateProfile(_profile);

    notifyListeners();
    await _saveJournals();
  }

  Future<void> deleteJournalEntry(String entryId) async {
    _journals.removeWhere((j) => j.id == entryId);
    notifyListeners();
    await _saveJournals();
  }

  int calculateStreak() {
    if (_journals.isEmpty) return 0;

    // Collect unique dates (ignoring time) in descending order
    final uniqueDays = <DateTime>{};
    for (final j in _journals) {
      uniqueDays.add(DateTime(j.date.year, j.date.month, j.date.day));
    }
    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak is active if student has an entry today or yesterday
    if (!uniqueDays.contains(today) && !uniqueDays.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = uniqueDays.contains(today) ? today : yesterday;

    for (final day in sortedDays) {
      if (day == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (day.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  // --- Timetable & Exams Methods ---
  Future<void> addExam(ExamItem exam) async {
    _exams.add(exam);
    _exams.sort((a, b) => a.examDate.compareTo(b.examDate));
    notifyListeners();
    await _saveExams();
  }

  Future<void> deleteExam(String id) async {
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveExams();
  }

  // --- Backup & Restore Engine ---
  Future<StuDeskBackupPayload> createBackupPayload() async {
    final now = DateTime.now();
    final serializedData = jsonEncode({
      'profile': _profile.toJson(),
      'courses': _courses.map((c) => c.toJson()).toList(),
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'resources': _resources.map((r) => r.toJson()).toList(),
      'journals': _journals.map((j) => j.toJson()).toList(),
      'subject_attendance': _subjectAttendance.map((a) => a.toJson()).toList(),
      'college_attendance': _collegeAttendance.map((a) => a.toJson()).toList(),
      'timetable': _timetable.map((t) => t.toJson()).toList(),
      'exams': _exams.map((e) => e.toJson()).toList(),
    });

    final checksum = StuDeskBackupPayload.generateChecksum(serializedData);

    final metadata = BackupMetadata(
      appVersion: '1.0.0',
      schemaVersion: StuDeskBackupPayload.currentSchemaVersion,
      exportedAt: now,
      deviceName: 'StuDesk Local Companion',
      coursesCount: _courses.length,
      tasksCount: _tasks.length,
      resourcesCount: _resources.length,
      journalsCount: _journals.length,
      attendanceRecordsCount: _subjectAttendance.length + _collegeAttendance.length,
      dataChecksum: checksum,
    );

    return StuDeskBackupPayload(
      metadata: metadata,
      profile: _profile,
      courses: List.from(_courses),
      tasks: List.from(_tasks),
      resources: List.from(_resources),
      journals: List.from(_journals),
      subjectAttendance: List.from(_subjectAttendance),
      collegeAttendance: List.from(_collegeAttendance),
      timetable: List.from(_timetable),
      exams: List.from(_exams),
    );
  }

  Future<void> restoreFromBackupPayload(
    StuDeskBackupPayload payload, {
    RestoreConflictStrategy strategy = RestoreConflictStrategy.overwrite,
  }) async {
    if (strategy == RestoreConflictStrategy.overwrite) {
      _profile = payload.profile;
      _courses = List.from(payload.courses);
      _tasks = List.from(payload.tasks);
      _resources = List.from(payload.resources);
      _journals = List.from(payload.journals);
      _subjectAttendance = List.from(payload.subjectAttendance);
      _collegeAttendance = List.from(payload.collegeAttendance);
      _timetable = List.from(payload.timetable);
      _exams = List.from(payload.exams);
    } else {
      // Merge strategies
      final existingTaskIds = _tasks.map((t) => t.id).toSet();
      for (final t in payload.tasks) {
        if (!existingTaskIds.contains(t.id)) {
          _tasks.add(t);
        }
      }

      final existingCourseCodes = _courses.map((c) => c.code).toSet();
      for (final c in payload.courses) {
        if (!existingCourseCodes.contains(c.code)) {
          _courses.add(c);
        }
      }

      final existingResourceIds = _resources.map((r) => r.id).toSet();
      for (final r in payload.resources) {
        if (!existingResourceIds.contains(r.id)) {
          _resources.add(r);
        }
      }

      final existingJournalIds = _journals.map((j) => j.id).toSet();
      for (final j in payload.journals) {
        if (!existingJournalIds.contains(j.id)) {
          _journals.add(j);
        }
      }
    }

    notifyListeners();
    await _saveAll();
  }

  Future<void> resetToSampleData() async {
    _profile = UserProfile.defaultProfile();
    _courses = List.from(SampleData.courses);
    _tasks = SampleData.getInitialTasks();
    _resources = List.from(SampleData.libraryResources);
    _subjectAttendance.clear();
    final today = DateTime.now();
    _collegeAttendance = [
      CollegeAttendanceRecord(
        id: 'col-init-1',
        date: today.subtract(const Duration(days: 2)),
        isPresent: true,
        remarks: 'Present all lectures',
      ),
      CollegeAttendanceRecord(
        id: 'col-init-2',
        date: today.subtract(const Duration(days: 1)),
        isPresent: true,
        remarks: 'Present all lectures',
      ),
      CollegeAttendanceRecord(
        id: 'col-init-3',
        date: today,
        isPresent: true,
        remarks: 'On campus',
      ),
    ];
    _journals = [
      JournalEntry(
        id: 'jrn-init',
        date: DateTime.now(),
        mood: 'Deep Focus',
        streak: '14 Days',
        tasksCompleted: 4,
        totalTasks: 5,
        linkedCourses: const ['CS201', 'CS204'],
        learnedText:
            'Solid grasp on binary search tree rebalancing and Red-Black tree rotations in CS201. Reviewed kernel synchronization in CS204.',
        accomplishments: const [
          'Finished OS Lab 4 kernel sync schema draft.',
          '30-min LeetCode practice completed.',
        ],
        tags: const ['Algorithms', 'Systems', 'Daily'],
        wordCount: 142,
      ),
    ];
    notifyListeners();
    await _saveAll();
  }

  // --- Private SharedPreferences Savers ---
  Future<void> _saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCourses, jsonEncode(_courses.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTasks, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> _saveResources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefResources, jsonEncode(_resources.map((r) => r.toJson()).toList()));
  }

  Future<void> _saveJournals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefJournals, jsonEncode(_journals.map((j) => j.toJson()).toList()));
  }

  Future<void> _saveSubjectAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefSubjectAttendance,
      jsonEncode(_subjectAttendance.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> _saveCollegeAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefCollegeAttendance,
      jsonEncode(_collegeAttendance.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> _saveTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTimetable, jsonEncode(_timetable.map((t) => t.toJson()).toList()));
  }

  Future<void> _saveExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefExams, jsonEncode(_exams.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveAll() async {
    await _saveCourses();
    await _saveTasks();
    await _saveResources();
    await _saveJournals();
    await _saveSubjectAttendance();
    await _saveCollegeAttendance();
    await _saveTimetable();
    await _saveExams();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProfile, jsonEncode(_profile.toJson()));
  }
}
