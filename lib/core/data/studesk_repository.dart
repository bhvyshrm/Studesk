import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/models.dart';

/// Central single-source-of-truth repository for StuDesk.
/// Manages responsive offline-first persistence and transparent Supabase cloud synchronization.
/// Zero demo or hardcoded fake content is seeded for production user accounts.
class StuDeskRepository extends ChangeNotifier {
  StuDeskRepository._();
  static final StuDeskRepository instance = StuDeskRepository._();

  static const String _prefProfile = 'studesk_profile';
  static const String _prefCourses = 'studesk_courses';
  static const String _prefTasks = 'studesk_tasks';
  static const String _prefEvents = 'studesk_events';
  static const String _prefExams = 'studesk_exams';
  static const String _prefReminders = 'studesk_reminders';
  static const String _prefNotes = 'studesk_notes';
  static const String _prefCollections = 'studesk_collections';
  static const String _prefResources = 'studesk_resources';
  static const String _prefJournals = 'studesk_journals';
  static const String _prefSubjectAttendance = 'studesk_subject_attendance';
  static const String _prefCollegeAttendance = 'studesk_college_attendance';
  static const String _prefTimetable = 'studesk_timetable';
  static const String _prefNotifications = 'studesk_notifications';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  UserProfile _profile = UserProfile.emptyProfile();
  List<Course> _courses = [];
  List<TaskItem> _tasks = [];
  List<EventItem> _events = [];
  List<ExamItem> _exams = [];
  List<ReminderItem> _reminders = [];
  List<AcademicNote> _notes = [];
  List<LibraryCollection> _collections = [];
  List<LibraryResource> _resources = [];
  List<JournalEntry> _journals = [];
  List<SubjectAttendanceRecord> _subjectAttendance = [];
  List<CollegeAttendanceRecord> _collegeAttendance = [];
  List<TimetableEntry> _timetable = [];
  List<InAppNotificationItem> _notifications = [];

  // Getters - Immutable views
  UserProfile get profile => _profile;
  List<Course> get courses => List.unmodifiable(_courses);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<EventItem> get events => List.unmodifiable(_events);
  List<ExamItem> get exams => List.unmodifiable(_exams);
  List<ReminderItem> get reminders => List.unmodifiable(_reminders);
  List<AcademicNote> get notes => List.unmodifiable(_notes);
  List<LibraryCollection> get collections => List.unmodifiable(_collections);
  List<LibraryResource> get resources => List.unmodifiable(_resources);
  List<JournalEntry> get journals => List.unmodifiable(_journals);
  List<SubjectAttendanceRecord> get subjectAttendance =>
      List.unmodifiable(_subjectAttendance);
  List<CollegeAttendanceRecord> get collegeAttendance =>
      List.unmodifiable(_collegeAttendance);
  List<TimetableEntry> get timetable => List.unmodifiable(_timetable);
  List<InAppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  // --- Notification Center Analytics ---
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead && !n.isDismissed).length;

  // --- Attendance Analytics: STRICTLY COUNTS ONLY (Rule 1.4: NO PERCENTAGES in UI) ---
  int get totalAttendedLectures =>
      _courses.fold(0, (acc, c) => acc + c.attendedLectures);
  int get totalLectures => _courses.fold(0, (acc, c) => acc + c.totalLectures);
  int get totalMissedLectures =>
      (totalLectures - totalAttendedLectures).clamp(0, 99999);

  String get attendanceSummaryHeadline {
    if (totalLectures == 0) {
      return 'No attendance recorded yet';
    }
    return '$totalAttendedLectures classes attended';
  }

  String get attendanceSummaryDetail {
    if (totalLectures == 0) {
      return 'Mark attendance from today\'s classes or Profile';
    }
    return '$totalLectures total recorded • $totalMissedLectures absences';
  }

  /// Internal percentage calculation for legacy tests or safe threshold calculations
  double get overallAttendancePercentage {
    final total = totalLectures;
    if (total == 0) return 100.0;
    return (totalAttendedLectures / total) * 100.0;
  }

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

  bool get isAttendanceSafe {
    if (totalLectures == 0) return true;
    return (totalAttendedLectures / totalLectures) >= 0.75;
  }

  // --- Task Analytics ---
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => _tasks.length;
  int get remainingTasksCount => totalTasksCount - completedTasksCount;

  // --- Exam Analytics ---
  ExamItem? get nextUpcomingExam {
    if (_exams.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _exams.where((e) {
      final examDay = DateTime(
        e.examDate.year,
        e.examDate.month,
        e.examDate.day,
      );
      return !examDay.isBefore(today);
    }).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.examDate.compareTo(b.examDate));
    return upcoming.first;
  }

  // --- Timetable & Lecture Helpers ---
  List<TimetableEntry> getTimetableForDay(int dayOfWeek) {
    return _timetable.where((t) => t.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  TimetableEntry? get nextOrCurrentTimetableEntry {
    final weekday = DateTime.now().weekday;
    final todayEntries = getTimetableForDay(weekday);
    if (todayEntries.isNotEmpty) return todayEntries.first;
    if (_timetable.isNotEmpty) return _timetable.first;
    return null;
  }

  // --- Today's Schedule Aggregation ---
  List<TimetableEntry> get todayClasses {
    final weekday = DateTime.now().weekday;
    return getTimetableForDay(weekday);
  }

  List<TaskItem> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
  }

  List<ExamItem> get todayExams {
    final now = DateTime.now();
    return _exams.where((e) {
      return e.examDate.year == now.year &&
          e.examDate.month == now.month &&
          e.examDate.day == now.day;
    }).toList();
  }

  List<EventItem> get todayEvents {
    final now = DateTime.now();
    return _events.where((e) {
      return e.eventDate.year == now.year &&
          e.eventDate.month == now.month &&
          e.eventDate.day == now.day;
    }).toList();
  }

  List<ReminderItem> get todayReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      return r.reminderTime.year == now.year &&
          r.reminderTime.month == now.month &&
          r.reminderTime.day == now.day;
    }).toList();
  }

  // --- Initialization & Local Storage ---
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Profile
      final profileStr = prefs.getString(_prefProfile);
      if (profileStr != null) {
        _profile = UserProfile.fromJson(
          jsonDecode(profileStr) as Map<String, dynamic>,
        );
      }

      // Courses
      final coursesStr = prefs.getString(_prefCourses);
      if (coursesStr != null) {
        final list = jsonDecode(coursesStr) as List<dynamic>;
        _courses = list
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Tasks
      final tasksStr = prefs.getString(_prefTasks);
      if (tasksStr != null) {
        final list = jsonDecode(tasksStr) as List<dynamic>;
        _tasks = list
            .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Events
      final eventsStr = prefs.getString(_prefEvents);
      if (eventsStr != null) {
        final list = jsonDecode(eventsStr) as List<dynamic>;
        _events = list
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Exams
      final examsStr = prefs.getString(_prefExams);
      if (examsStr != null) {
        final list = jsonDecode(examsStr) as List<dynamic>;
        _exams = list
            .map((e) => ExamItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Reminders
      final remindersStr = prefs.getString(_prefReminders);
      if (remindersStr != null) {
        final list = jsonDecode(remindersStr) as List<dynamic>;
        _reminders = list
            .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Academic Notes
      final notesStr = prefs.getString(_prefNotes);
      if (notesStr != null) {
        final list = jsonDecode(notesStr) as List<dynamic>;
        _notes = list
            .map((e) => AcademicNote.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Collections
      final collectionsStr = prefs.getString(_prefCollections);
      if (collectionsStr != null) {
        final list = jsonDecode(collectionsStr) as List<dynamic>;
        _collections = list
            .map((e) => LibraryCollection.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Resources
      final resourcesStr = prefs.getString(_prefResources);
      if (resourcesStr != null) {
        final list = jsonDecode(resourcesStr) as List<dynamic>;
        _resources = list
            .map((e) => LibraryResource.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Journals
      final journalsStr = prefs.getString(_prefJournals);
      if (journalsStr != null) {
        final list = jsonDecode(journalsStr) as List<dynamic>;
        _journals = list
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Subject Attendance
      final subAttStr = prefs.getString(_prefSubjectAttendance);
      if (subAttStr != null) {
        final list = jsonDecode(subAttStr) as List<dynamic>;
        _subjectAttendance = list
            .map(
              (e) =>
                  SubjectAttendanceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      // College Attendance
      final colAttStr = prefs.getString(_prefCollegeAttendance);
      if (colAttStr != null) {
        final list = jsonDecode(colAttStr) as List<dynamic>;
        _collegeAttendance = list
            .map(
              (e) =>
                  CollegeAttendanceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      // Timetable
      final timetableStr = prefs.getString(_prefTimetable);
      if (timetableStr != null) {
        final list = jsonDecode(timetableStr) as List<dynamic>;
        _timetable = list
            .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // In-App Notifications
      final notifsStr = prefs.getString(_prefNotifications);
      if (notifsStr != null) {
        final list = jsonDecode(notifsStr) as List<dynamic>;
        _notifications = list
            .map(
              (e) => InAppNotificationItem.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      _isInitialized = true;
      _deriveInitialNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('StuDeskRepository initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _deriveInitialNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Check upcoming exams within next 7 days
    for (final exam in _exams) {
      final diff = exam.examDate.difference(today).inDays;
      if (diff >= 0 && diff <= 7) {
        final notifId = 'notif_exam_${exam.id}';
        if (!_notifications.any((n) => n.id == notifId)) {
          _notifications.insert(
            0,
            InAppNotificationItem(
              id: notifId,
              title: 'Upcoming Exam: ${exam.title}',
              body: diff == 0
                  ? 'Exam is scheduled for today in ${exam.room}!'
                  : 'Scheduled in $diff days (${exam.courseCode})',
              type: NotificationType.exam,
              recordId: exam.id,
              createdAt: now,
            ),
          );
        }
      }
    }

    // 2. Check tasks due today or overdue
    for (final task in _tasks.where((t) => !t.isCompleted)) {
      if (task.dueDate != null) {
        final taskDay = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (!taskDay.isAfter(today)) {
          final notifId = 'notif_task_${task.id}';
          if (!_notifications.any((n) => n.id == notifId)) {
            _notifications.insert(
              0,
              InAppNotificationItem(
                id: notifId,
                title: 'Task Due: ${task.title}',
                body: taskDay.isBefore(today)
                    ? 'This task is overdue'
                    : 'Due today (${task.dueTime ?? 'Anytime'})',
                type: NotificationType.task,
                recordId: task.id,
                createdAt: now,
              ),
            );
          }
        }
      }
    }
  }

  // --- User Account & Profile Operations ---
  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProfile, jsonEncode(_profile.toJson()));
    _syncProfileToSupabase();
  }

  Future<void> clearUserSessionData() async {
    _profile = UserProfile.emptyProfile();
    _courses = [];
    _tasks = [];
    _events = [];
    _exams = [];
    _reminders = [];
    _notes = [];
    _collections = [];
    _resources = [];
    _journals = [];
    _subjectAttendance = [];
    _collegeAttendance = [];
    _timetable = [];
    _notifications = [];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefProfile);
    await prefs.remove(_prefCourses);
    await prefs.remove(_prefTasks);
    await prefs.remove(_prefEvents);
    await prefs.remove(_prefExams);
    await prefs.remove(_prefReminders);
    await prefs.remove(_prefNotes);
    await prefs.remove(_prefCollections);
    await prefs.remove(_prefResources);
    await prefs.remove(_prefJournals);
    await prefs.remove(_prefSubjectAttendance);
    await prefs.remove(_prefCollegeAttendance);
    await prefs.remove(_prefTimetable);
    await prefs.remove(_prefNotifications);
  }

  // --- Task Methods ---
  Future<void> addTask(TaskItem task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _saveTasks();
    _syncTaskToSupabase(task);
  }

  Future<void> updateTask(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
      await _saveTasks();
      _syncTaskToSupabase(task);
    }
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
      await _saveTasks();
      _syncTaskToSupabase(_tasks[index]);
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _saveTasks();
    _deleteTaskFromSupabase(taskId);
  }

  // --- Event Methods ---
  Future<void> addEvent(EventItem event) async {
    _events.insert(0, event);
    _events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    notifyListeners();
    await _saveEvents();
    _syncEventToSupabase(event);
  }

  Future<void> updateEvent(EventItem event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      _events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      notifyListeners();
      await _saveEvents();
      _syncEventToSupabase(event);
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveEvents();
    _deleteEventFromSupabase(id);
  }

  // --- Exam Methods ---
  Future<void> addExam(ExamItem exam) async {
    _exams.add(exam);
    _exams.sort((a, b) => a.examDate.compareTo(b.examDate));
    _deriveInitialNotifications();
    notifyListeners();
    await _saveExams();
    _syncExamToSupabase(exam);
  }

  Future<void> updateExam(ExamItem exam) async {
    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
      _exams.sort((a, b) => a.examDate.compareTo(b.examDate));
      notifyListeners();
      await _saveExams();
      _syncExamToSupabase(exam);
    }
  }

  Future<void> deleteExam(String id) async {
    _exams.removeWhere((e) => e.id == id);
    _notifications.removeWhere((n) => n.recordId == id);
    notifyListeners();
    await _saveExams();
    _deleteExamFromSupabase(id);
  }

  // --- Reminder Methods ---
  Future<void> addReminder(ReminderItem reminder) async {
    _reminders.insert(0, reminder);
    _reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    notifyListeners();
    await _saveReminders();
    _syncReminderToSupabase(reminder);
  }

  Future<void> updateReminder(ReminderItem reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      _reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
      notifyListeners();
      await _saveReminders();
      _syncReminderToSupabase(reminder);
    }
  }

  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: !_reminders[index].isCompleted,
      );
      notifyListeners();
      await _saveReminders();
      _syncReminderToSupabase(_reminders[index]);
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _saveReminders();
    _deleteReminderFromSupabase(id);
  }

  // --- Academic Course / Subject Methods ---
  Future<void> addCourse(Course course) async {
    _courses.add(course);
    notifyListeners();
    await _saveCourses();
    _syncCourseToSupabase(course);
  }

  Future<void> updateCourse(Course updatedCourse) async {
    final index = _courses.indexWhere((c) => c.code == updatedCourse.code);
    if (index != -1) {
      _courses[index] = updatedCourse;
      notifyListeners();
      await _saveCourses();
      _syncCourseToSupabase(updatedCourse);
    }
  }

  Future<void> deleteCourse(String code) async {
    _courses.removeWhere((c) => c.code == code);
    notifyListeners();
    await _saveCourses();
    _deleteCourseFromSupabase(code);
  }

  Future<void> toggleTopicCompletion(
    String courseCode,
    int unitNumber,
    String topicId,
  ) async {
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

  // --- Academic Notes & Coursework File Methods ---
  Future<void> addAcademicNote(AcademicNote note) async {
    _notes.insert(0, note);
    notifyListeners();
    await _saveNotes();
    _syncAcademicNoteToSupabase(note);
  }

  Future<void> updateAcademicNote(AcademicNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      notifyListeners();
      await _saveNotes();
      _syncAcademicNoteToSupabase(note);
    }
  }

  Future<void> deleteAcademicNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotes();
    _deleteAcademicNoteFromSupabase(id);
  }

  // --- Attendance Methods ---
  Future<void> logSubjectAttendance(
    String courseCode, {
    required bool isPresent,
    String? slot,
    String? topic,
  }) async {
    final record = SubjectAttendanceRecord(
      id: const Uuid().v4(),
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
      final newAttended = isPresent
          ? course.attendedLectures + 1
          : course.attendedLectures;
      final newTotal = course.totalLectures + 1;
      _courses[cIndex] = course.copyWith(
        attendedLectures: newAttended,
        totalLectures: newTotal,
      );
      await _saveCourses();
      _syncCourseToSupabase(_courses[cIndex]);
    }

    notifyListeners();
    await _saveSubjectAttendance();
    _syncSubjectAttendanceToSupabase(record);
  }

  Future<void> correctSubjectAttendanceRecord(
    String recordId,
    bool newStatus,
  ) async {
    final rIndex = _subjectAttendance.indexWhere((r) => r.id == recordId);
    if (rIndex == -1) return;

    final oldRecord = _subjectAttendance[rIndex];
    if (oldRecord.isPresent == newStatus) return;

    _subjectAttendance[rIndex] = oldRecord.copyWith(isPresent: newStatus);

    final cIndex = _courses.indexWhere((c) => c.code == oldRecord.courseCode);
    if (cIndex != -1) {
      final course = _courses[cIndex];
      final attendedDelta = newStatus ? 1 : -1;
      _courses[cIndex] = course.copyWith(
        attendedLectures: (course.attendedLectures + attendedDelta).clamp(
          0,
          course.totalLectures,
        ),
      );
      await _saveCourses();
      _syncCourseToSupabase(_courses[cIndex]);
    }

    notifyListeners();
    await _saveSubjectAttendance();
    _syncSubjectAttendanceToSupabase(_subjectAttendance[rIndex]);
  }

  List<SubjectAttendanceRecord> getAttendanceHistoryForSubject(
    String courseCode,
  ) {
    return _subjectAttendance.where((r) => r.courseCode == courseCode).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> logCollegeAttendance(
    DateTime date,
    bool isPresent, {
    String? remarks,
  }) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final existingIndex = _collegeAttendance.indexWhere(
      (r) =>
          r.date.year == targetDate.year &&
          r.date.month == targetDate.month &&
          r.date.day == targetDate.day,
    );

    late CollegeAttendanceRecord targetRecord;
    if (existingIndex != -1) {
      targetRecord = _collegeAttendance[existingIndex].copyWith(
        isPresent: isPresent,
        remarks: remarks,
      );
      _collegeAttendance[existingIndex] = targetRecord;
    } else {
      targetRecord = CollegeAttendanceRecord(
        id: const Uuid().v4(),
        date: targetDate,
        isPresent: isPresent,
        remarks: remarks,
      );
      _collegeAttendance.add(targetRecord);
    }

    notifyListeners();
    await _saveCollegeAttendance();
    _syncCollegeAttendanceToSupabase(targetRecord);
  }

  bool? getCollegeAttendanceForDate(DateTime date) {
    final match = _collegeAttendance
        .cast<CollegeAttendanceRecord?>()
        .firstWhere(
          (r) =>
              r != null &&
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
          orElse: () => null,
        );
    return match?.isPresent;
  }

  // --- Timetable Methods ---
  Future<void> addTimetableEntry(TimetableEntry entry) async {
    _timetable.add(entry);
    notifyListeners();
    await _saveTimetable();
    _syncTimetableToSupabase(entry);
  }

  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    final index = _timetable.indexWhere((t) => t.id == entry.id);
    if (index != -1) {
      _timetable[index] = entry;
      notifyListeners();
      await _saveTimetable();
      _syncTimetableToSupabase(entry);
    }
  }

  Future<void> deleteTimetableEntry(String id) async {
    _timetable.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTimetable();
    _deleteTimetableFromSupabase(id);
  }

  // --- Library Collection & Resource Methods ---
  Future<void> addCollection(LibraryCollection collection) async {
    _collections.add(collection);
    notifyListeners();
    await _saveCollections();
    _syncCollectionToSupabase(collection);
  }

  Future<void> updateCollection(LibraryCollection collection) async {
    final index = _collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      _collections[index] = collection;
      notifyListeners();
      await _saveCollections();
      _syncCollectionToSupabase(collection);
    }
  }

  Future<void> deleteCollection(String id) async {
    _collections.removeWhere((c) => c.id == id);
    for (int i = 0; i < _resources.length; i++) {
      if (_resources[i].collectionId == id) {
        _resources[i] = _resources[i].copyWith(collectionId: null);
      }
    }
    notifyListeners();
    await _saveCollections();
    await _saveResources();
    _deleteCollectionFromSupabase(id);
  }

  Future<void> addResource(LibraryResource resource) async {
    _resources.insert(0, resource);
    notifyListeners();
    await _saveResources();
    _syncResourceToSupabase(resource);
  }

  Future<void> updateResource(LibraryResource resource) async {
    final index = _resources.indexWhere((r) => r.id == resource.id);
    if (index != -1) {
      _resources[index] = resource;
      notifyListeners();
      await _saveResources();
      _syncResourceToSupabase(resource);
    }
  }

  Future<void> toggleResourceBookmark(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index != -1) {
      final current = _resources[index];
      _resources[index] = current.copyWith(isBookmarked: !current.isBookmarked);
      notifyListeners();
      await _saveResources();
      _syncResourceToSupabase(_resources[index]);
    }
  }

  Future<void> deleteResource(String resourceId) async {
    _resources.removeWhere((r) => r.id == resourceId);
    notifyListeners();
    await _saveResources();
    _deleteResourceFromSupabase(resourceId);
  }

  // --- Journal & Streaks Methods ---
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final index = _journals.indexWhere((j) => j.id == entry.id);
    if (index != -1) {
      _journals[index] = entry;
    } else {
      _journals.insert(0, entry);
    }

    final currentStreak = calculateStreak();
    _profile = _profile.copyWith(
      streakDays: currentStreak,
      lastActiveDate: DateTime.now(),
    );
    await updateProfile(_profile);

    notifyListeners();
    await _saveJournals();
    _syncJournalToSupabase(entry);
  }

  Future<void> deleteJournalEntry(String entryId) async {
    _journals.removeWhere((j) => j.id == entryId);
    notifyListeners();
    await _saveJournals();
    _deleteJournalFromSupabase(entryId);
  }

  int calculateStreak() {
    if (_journals.isEmpty) return 0;

    final uniqueDays = <DateTime>{};
    for (final j in _journals) {
      uniqueDays.add(DateTime(j.date.year, j.date.month, j.date.day));
    }
    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

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

  // --- Notification Center Methods ---
  void markNotificationAsRead(String notifId) {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      _saveNotifications();
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
    _saveNotifications();
  }

  void dismissNotification(String notifId) {
    _notifications.removeWhere((n) => n.id == notifId);
    notifyListeners();
    _saveNotifications();
  }

  // --- Backup & Restore Engine ---
  Future<StuDeskBackupPayload> createBackupPayload() async {
    final now = DateTime.now();
    final serializedData = jsonEncode({
      'profile': _profile.toJson(),
      'courses': _courses.map((c) => c.toJson()).toList(),
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'events': _events.map((e) => e.toJson()).toList(),
      'exams': _exams.map((e) => e.toJson()).toList(),
      'reminders': _reminders.map((r) => r.toJson()).toList(),
      'notes': _notes.map((n) => n.toJson()).toList(),
      'collections': _collections.map((c) => c.toJson()).toList(),
      'resources': _resources.map((r) => r.toJson()).toList(),
      'journals': _journals.map((j) => j.toJson()).toList(),
      'subject_attendance': _subjectAttendance.map((a) => a.toJson()).toList(),
      'college_attendance': _collegeAttendance.map((a) => a.toJson()).toList(),
      'timetable': _timetable.map((t) => t.toJson()).toList(),
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
      attendanceRecordsCount:
          _subjectAttendance.length + _collegeAttendance.length,
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

  /// Clean test fixture reset: clears all in-memory collections and cache
  Future<void> resetForTesting() async {
    _profile = UserProfile.emptyProfile();
    _courses = [];
    _tasks = [];
    _events = [];
    _exams = [];
    _reminders = [];
    _notes = [];
    _collections = [];
    _resources = [];
    _journals = [];
    _subjectAttendance = [];
    _collegeAttendance = [];
    _timetable = [];
    _notifications = [];
    notifyListeners();
    await _saveAll();
  }

  // --- Global Search Method ---
  List<Map<String, dynamic>> searchAll(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final results = <Map<String, dynamic>>[];

    // 1. Tasks
    for (final task in _tasks) {
      if (task.title.toLowerCase().contains(trimmed) ||
          (task.detail?.toLowerCase().contains(trimmed) ?? false) ||
          task.categoryTag.toLowerCase().contains(trimmed)) {
        results.add({
          'type': 'Task',
          'title': task.title,
          'subtitle': task.dueTime != null ? 'Due: ${task.dueTime}' : 'Task',
          'item': task,
        });
      }
    }

    // 2. Exams
    for (final exam in _exams) {
      if (exam.title.toLowerCase().contains(trimmed) ||
          exam.courseCode.toLowerCase().contains(trimmed) ||
          exam.syllabusCutoff.toLowerCase().contains(trimmed)) {
        results.add({
          'type': 'Exam',
          'title': exam.title,
          'subtitle': '${exam.courseCode} • Room ${exam.room}',
          'item': exam,
        });
      }
    }

    // 3. Events
    for (final event in _events) {
      if (event.title.toLowerCase().contains(trimmed) ||
          (event.notes?.toLowerCase().contains(trimmed) ?? false) ||
          (event.location?.toLowerCase().contains(trimmed) ?? false)) {
        results.add({
          'type': 'Event',
          'title': event.title,
          'subtitle': event.location != null ? 'At ${event.location}' : 'Event',
          'item': event,
        });
      }
    }

    // 4. Subjects
    for (final course in _courses) {
      if (course.title.toLowerCase().contains(trimmed) ||
          course.code.toLowerCase().contains(trimmed) ||
          course.professor.toLowerCase().contains(trimmed)) {
        results.add({
          'type': 'Subject',
          'title': course.title,
          'subtitle': '${course.code} • ${course.professor}',
          'item': course,
        });
      }
    }

    // 5. Academic Notes
    for (final note in _notes) {
      if (note.title.toLowerCase().contains(trimmed) ||
          note.subjectCode.toLowerCase().contains(trimmed) ||
          note.content.toLowerCase().contains(trimmed)) {
        results.add({
          'type': 'Note',
          'title': note.title,
          'subtitle':
              '${note.subjectCode} • ${note.fileType.name.toUpperCase()}',
          'item': note,
        });
      }
    }

    // 6. Library Resources
    for (final res in _resources) {
      if (res.title.toLowerCase().contains(trimmed) ||
          res.subjectTag.toLowerCase().contains(trimmed) ||
          (res.channel?.toLowerCase().contains(trimmed) ?? false)) {
        results.add({
          'type': 'Library',
          'title': res.title,
          'subtitle': '${res.type.name.toUpperCase()} • ${res.subjectTag}',
          'item': res,
        });
      }
    }

    // 7. Timetable
    for (final tt in _timetable) {
      if (tt.title.toLowerCase().contains(trimmed) ||
          tt.courseCode.toLowerCase().contains(trimmed) ||
          tt.room.toLowerCase().contains(trimmed)) {
        results.add({
          'type': 'Class',
          'title': tt.title,
          'subtitle': '${tt.courseCode} • ${tt.startTime} - ${tt.endTime}',
          'item': tt,
        });
      }
    }

    return results;
  }

  // --- Private SharedPreferences Savers ---
  Future<void> _saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefCourses,
      jsonEncode(_courses.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefTasks,
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefEvents,
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefExams,
      jsonEncode(_exams.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefReminders,
      jsonEncode(_reminders.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefNotes,
      jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _saveCollections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefCollections,
      jsonEncode(_collections.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _saveResources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefResources,
      jsonEncode(_resources.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _saveJournals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefJournals,
      jsonEncode(_journals.map((j) => j.toJson()).toList()),
    );
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
    await prefs.setString(
      _prefTimetable,
      jsonEncode(_timetable.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefNotifications,
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _saveAll() async {
    await _saveCourses();
    await _saveTasks();
    await _saveEvents();
    await _saveExams();
    await _saveReminders();
    await _saveNotes();
    await _saveCollections();
    await _saveResources();
    await _saveJournals();
    await _saveSubjectAttendance();
    await _saveCollegeAttendance();
    await _saveTimetable();
    await _saveNotifications();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProfile, jsonEncode(_profile.toJson()));
  }

  // --- UUID Validation & Sanitization Helpers ---
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isUuid(String str) => _uuidRegex.hasMatch(str.trim());

  static String safeUuid(String str) {
    final trimmed = str.trim();
    if (isUuid(trimmed)) return trimmed;
    return const Uuid().v4();
  }

  // --- Background Supabase Cloud Synchronizers ---
  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _syncProfileToSupabase() async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('profiles').upsert(_profile.toSupabaseMap());
      }
    } catch (e) {
      debugPrint('Sync profile error: $e');
    }
  }

  void _syncTaskToSupabase(TaskItem task) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('tasks').upsert({
          'id': safeUuid(task.id),
          'user_id': user.id,
          'title': task.title,
          'priority': task.priority.name,
          'due_time': task.dueTime,
          'due_date': task.dueDate?.toIso8601String(),
          'category_tag': task.categoryTag,
          'detail': task.detail,
          'course_code': task.courseCode,
          'is_recurring': task.isRecurring,
          'is_completed': task.isCompleted,
        });
      }
    } catch (e) {
      debugPrint('Sync task error: $e');
    }
  }

  void _deleteTaskFromSupabase(String taskId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(taskId)) {
        await client.from('tasks').delete().eq('id', taskId);
      }
    } catch (e) {
      debugPrint('Delete task error: $e');
    }
  }

  void _syncEventToSupabase(EventItem event) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('events').upsert({
          'id': safeUuid(event.id),
          'user_id': user.id,
          'title': event.title,
          'event_date': event.eventDate.toIso8601String(),
          'start_time': event.startTime,
          'end_time': event.endTime,
          'location': event.location,
          'notes': event.notes,
          'has_reminder': event.hasReminder,
        });
      }
    } catch (e) {
      debugPrint('Sync event error: $e');
    }
  }

  void _deleteEventFromSupabase(String eventId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(eventId)) {
        await client.from('events').delete().eq('id', eventId);
      }
    } catch (e) {
      debugPrint('Delete event error: $e');
    }
  }

  void _syncExamToSupabase(ExamItem exam) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('exams').upsert({
          'id': safeUuid(exam.id),
          'user_id': user.id,
          'course_code': exam.courseCode,
          'title': exam.title,
          'exam_date': exam.examDate.toIso8601String(),
          'room': exam.room,
          'syllabus_cutoff': exam.syllabusCutoff,
          'weightage_percent': exam.weightagePercent,
        });
      }
    } catch (e) {
      debugPrint('Sync exam error: $e');
    }
  }

  void _deleteExamFromSupabase(String examId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(examId)) {
        await client.from('exams').delete().eq('id', examId);
      }
    } catch (e) {
      debugPrint('Delete exam error: $e');
    }
  }

  void _syncReminderToSupabase(ReminderItem reminder) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('reminders').upsert({
          'id': safeUuid(reminder.id),
          'user_id': user.id,
          'text': reminder.text,
          'reminder_time': reminder.reminderTime.toIso8601String(),
          'repeat_rule': reminder.repeatRule,
          'linked_id': reminder.linkedId,
          'linked_type': reminder.linkedType,
          'is_completed': reminder.isCompleted,
        });
      }
    } catch (e) {
      debugPrint('Sync reminder error: $e');
    }
  }

  void _deleteReminderFromSupabase(String reminderId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(reminderId)) {
        await client.from('reminders').delete().eq('id', reminderId);
      }
    } catch (e) {
      debugPrint('Delete reminder error: $e');
    }
  }

  void _syncCourseToSupabase(Course course) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('courses').upsert({
          'user_id': user.id,
          'code': course.code,
          'title': course.title,
          'professor': course.professor,
          'department': course.department,
          'schedule': course.schedule,
          'location': course.location,
          'credits': course.credits,
          'attended_lectures': course.attendedLectures,
          'total_lectures': course.totalLectures,
          'grade': course.grade,
          'standing': course.standing,
          'last_topic': course.lastTopic,
          'is_warning': course.isWarning,
        }, onConflict: 'user_id,code');
      }
    } catch (e) {
      debugPrint('Sync course error: $e');
    }
  }

  void _deleteCourseFromSupabase(String courseCode) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('courses').delete().match({
          'user_id': user.id,
          'code': courseCode,
        });
      }
    } catch (e) {
      debugPrint('Delete course error: $e');
    }
  }

  void _syncAcademicNoteToSupabase(AcademicNote note) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('academic_notes').upsert({
          'id': safeUuid(note.id),
          'user_id': user.id,
          'title': note.title,
          'subject_code': note.subjectCode,
          'file_type': note.fileType.name,
          'file_url': note.fileUrl,
          'content': note.content,
          'file_size': note.fileSize,
        });
      }
    } catch (e) {
      debugPrint('Sync academic note error: $e');
    }
  }

  void _deleteAcademicNoteFromSupabase(String noteId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(noteId)) {
        await client.from('academic_notes').delete().eq('id', noteId);
      }
    } catch (e) {
      debugPrint('Delete academic note error: $e');
    }
  }

  void _syncCollectionToSupabase(LibraryCollection collection) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('library_collections').upsert({
          'id': safeUuid(collection.id),
          'user_id': user.id,
          'name': collection.name,
          'description': collection.description,
          'color_hex': collection.colorHex,
        });
      }
    } catch (e) {
      debugPrint('Sync collection error: $e');
    }
  }

  void _deleteCollectionFromSupabase(String collectionId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(collectionId)) {
        await client
            .from('library_collections')
            .delete()
            .eq('id', collectionId);
      }
    } catch (e) {
      debugPrint('Delete collection error: $e');
    }
  }

  void _syncResourceToSupabase(LibraryResource resource) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('library_resources').upsert({
          'id': safeUuid(resource.id),
          'user_id': user.id,
          'title': resource.title,
          'type': resource.type.name,
          'subject_tag': resource.subjectTag,
          'url': resource.url,
          'note_content': resource.noteContent,
          'duration': resource.duration,
          'meta_info': resource.metaInfo,
          'channel': resource.channel,
          'is_bookmarked': resource.isBookmarked,
          'collection_id':
              (resource.collectionId != null && isUuid(resource.collectionId!))
              ? resource.collectionId
              : null,
          'description': resource.description,
        });
      }
    } catch (e) {
      debugPrint('Sync resource error: $e');
    }
  }

  void _deleteResourceFromSupabase(String resourceId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(resourceId)) {
        await client.from('library_resources').delete().eq('id', resourceId);
      }
    } catch (e) {
      debugPrint('Delete resource error: $e');
    }
  }

  void _syncTimetableToSupabase(TimetableEntry entry) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('timetable_entries').upsert({
          'id': safeUuid(entry.id),
          'user_id': user.id,
          'day_of_week': entry.dayOfWeek,
          'start_time': entry.startTime,
          'end_time': entry.endTime,
          'course_code': entry.courseCode,
          'title': entry.title,
          'room': entry.room,
          'professor': entry.professor,
        });
      }
    } catch (e) {
      debugPrint('Sync timetable error: $e');
    }
  }

  void _deleteTimetableFromSupabase(String timetableId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(timetableId)) {
        await client.from('timetable_entries').delete().eq('id', timetableId);
      }
    } catch (e) {
      debugPrint('Delete timetable error: $e');
    }
  }

  void _syncSubjectAttendanceToSupabase(SubjectAttendanceRecord record) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('subject_attendance').upsert({
          'id': safeUuid(record.id),
          'user_id': user.id,
          'course_code': record.courseCode,
          'date': record.date.toIso8601String(),
          'is_present': record.isPresent,
          'lecture_slot': record.lectureSlot,
          'topic_discussed': record.topicDiscussed,
        });
      }
    } catch (e) {
      debugPrint('Sync subject attendance error: $e');
    }
  }

  void _syncCollegeAttendanceToSupabase(CollegeAttendanceRecord record) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('college_attendance').upsert({
          'id': safeUuid(record.id),
          'user_id': user.id,
          'date': record.date.toIso8601String().split('T').first,
          'is_present': record.isPresent,
          'remarks': record.remarks,
        }, onConflict: 'user_id,date');
      }
    } catch (e) {
      debugPrint('Sync college attendance error: $e');
    }
  }

  void _syncJournalToSupabase(JournalEntry journal) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('journal_entries').upsert({
          'id': safeUuid(journal.id),
          'user_id': user.id,
          'date': journal.date.toIso8601String(),
          'mood': journal.mood,
          'streak': journal.streak,
          'tasks_completed': journal.tasksCompleted,
          'total_tasks': journal.totalTasks,
          'linked_courses': journal.linkedCourses,
          'learned_text': journal.learnedText,
          'code_snippet': journal.codeSnippet,
          'accomplishments': journal.accomplishments,
          'blocker': journal.blocker,
          'tags': journal.tags,
          'word_count': journal.wordCount,
        });
      }
    } catch (e) {
      debugPrint('Sync journal error: $e');
    }
  }

  void _deleteJournalFromSupabase(String journalId) async {
    try {
      final client = _supabaseClient;
      final user = client?.auth.currentUser;
      if (client != null && user != null && isUuid(journalId)) {
        await client.from('journal_entries').delete().eq('id', journalId);
      }
    } catch (e) {
      debugPrint('Delete journal error: $e');
    }
  }

  /// Full dynamic cloud synchronization:
  /// Loads all user records from Supabase tables for the authenticated student.
  Future<void> fetchAndSyncAllDataFromSupabase({User? user}) async {
    final client = _supabaseClient;
    if (client == null) return;
    final currentUser = user ?? client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Courses
      final coursesRes = await client
          .from('courses')
          .select()
          .eq('user_id', currentUser.id);
      if (coursesRes.isNotEmpty) {
        _courses = coursesRes.map((c) => Course.fromJson(c)).toList();
      }

      // 2. Tasks
      final tasksRes = await client
          .from('tasks')
          .select()
          .eq('user_id', currentUser.id);
      if (tasksRes.isNotEmpty) {
        _tasks = tasksRes.map((t) => TaskItem.fromJson(t)).toList();
      }

      // 3. Events
      final eventsRes = await client
          .from('events')
          .select()
          .eq('user_id', currentUser.id);
      if (eventsRes.isNotEmpty) {
        _events = eventsRes.map((e) => EventItem.fromJson(e)).toList();
      }

      // 4. Exams
      final examsRes = await client
          .from('exams')
          .select()
          .eq('user_id', currentUser.id);
      if (examsRes.isNotEmpty) {
        _exams = examsRes.map((e) => ExamItem.fromJson(e)).toList();
      }

      // 5. Reminders
      final remRes = await client
          .from('reminders')
          .select()
          .eq('user_id', currentUser.id);
      if (remRes.isNotEmpty) {
        _reminders = remRes.map((r) => ReminderItem.fromJson(r)).toList();
      }

      // 6. Academic Notes
      final notesRes = await client
          .from('academic_notes')
          .select()
          .eq('user_id', currentUser.id);
      if (notesRes.isNotEmpty) {
        _notes = notesRes.map((n) => AcademicNote.fromJson(n)).toList();
      }

      // 7. Collections
      final colRes = await client
          .from('library_collections')
          .select()
          .eq('user_id', currentUser.id);
      if (colRes.isNotEmpty) {
        _collections = colRes
            .map((c) => LibraryCollection.fromJson(c))
            .toList();
      }

      // 8. Resources
      final resRes = await client
          .from('library_resources')
          .select()
          .eq('user_id', currentUser.id);
      if (resRes.isNotEmpty) {
        _resources = resRes.map((r) => LibraryResource.fromJson(r)).toList();
      }

      // 9. Timetable
      final ttRes = await client
          .from('timetable_entries')
          .select()
          .eq('user_id', currentUser.id);
      if (ttRes.isNotEmpty) {
        _timetable = ttRes.map((t) => TimetableEntry.fromJson(t)).toList();
      }

      // 10. Subject Attendance
      final subAttRes = await client
          .from('subject_attendance')
          .select()
          .eq('user_id', currentUser.id);
      if (subAttRes.isNotEmpty) {
        _subjectAttendance = subAttRes
            .map((a) => SubjectAttendanceRecord.fromJson(a))
            .toList();
      }

      // 11. College Attendance
      final colAttRes = await client
          .from('college_attendance')
          .select()
          .eq('user_id', currentUser.id);
      if (colAttRes.isNotEmpty) {
        _collegeAttendance = colAttRes
            .map((a) => CollegeAttendanceRecord.fromJson(a))
            .toList();
      }

      // 12. Journal Entries
      final jRes = await client
          .from('journal_entries')
          .select()
          .eq('user_id', currentUser.id);
      if (jRes.isNotEmpty) {
        _journals = jRes.map((j) => JournalEntry.fromJson(j)).toList();
      }

      _deriveInitialNotifications();
      await _saveAll();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching data from Supabase: $e');
    }
  }
}
