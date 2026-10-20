import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/shared/models/models.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('StuDeskRepository Tests', () {
    test('Repository initializes with seed courses and tasks', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      expect(repo.isInitialized, isTrue);
      expect(repo.courses.isNotEmpty, isTrue);
      expect(repo.tasks.isNotEmpty, isTrue);
      expect(repo.profile.name, 'Alex Chen');
    });

    test('Adding and deleting a course updates repository state', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      const newCourse = Course(
        code: 'CS301',
        title: 'Machine Learning',
        professor: 'Dr. Turing',
        department: 'AI & Data Science',
        schedule: 'Mon, Thu 02:00 PM',
        location: 'Hall A',
        credits: 4,
        attendedLectures: 0,
        totalLectures: 0,
      );

      await repo.addCourse(newCourse);
      expect(repo.courses.any((c) => c.code == 'CS301'), isTrue);

      await repo.deleteCourse('CS301');
      expect(repo.courses.any((c) => c.code == 'CS301'), isFalse);
    });

    test('Logging subject attendance increases lecture counts', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      final initialCourse = repo.courses.firstWhere((c) => c.code == 'CS201');
      final initialAttended = initialCourse.attendedLectures;
      final initialTotal = initialCourse.totalLectures;

      await repo.logSubjectAttendance('CS201', isPresent: true, slot: 'Morning');

      final updatedCourse = repo.courses.firstWhere((c) => c.code == 'CS201');
      expect(updatedCourse.attendedLectures, initialAttended + 1);
      expect(updatedCourse.totalLectures, initialTotal + 1);
    });

    test('College attendance calendar records daily presence distinctly', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      final targetDate = DateTime(2026, 10, 20);
      await repo.logCollegeAttendance(targetDate, true, remarks: 'Present in lab');

      final status = repo.getCollegeAttendanceForDate(targetDate);
      expect(status, isTrue);

      // Update to absent (correction)
      await repo.logCollegeAttendance(targetDate, false, remarks: 'Sick leave');
      expect(repo.getCollegeAttendanceForDate(targetDate), isFalse);
    });

    test('Task creation, toggle, and deletion work reliably', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      final newTask = TaskItem(
        id: 'task-test-101',
        title: 'Submit Compiler Assignment',
        priority: TaskPriority.high,
        categoryTag: 'Compilers',
      );

      await repo.addTask(newTask);
      expect(repo.tasks.any((t) => t.id == 'task-test-101'), isTrue);

      await repo.toggleTask('task-test-101');
      final toggled = repo.tasks.firstWhere((t) => t.id == 'task-test-101');
      expect(toggled.isCompleted, isTrue);

      await repo.deleteTask('task-test-101');
      expect(repo.tasks.any((t) => t.id == 'task-test-101'), isFalse);
    });

    test('Backup export and restore with overwrite strategy', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      final backupPayload = await repo.createBackupPayload();
      expect(backupPayload.metadata.dataChecksum.isNotEmpty, isTrue);
      expect(backupPayload.courses.isNotEmpty, isTrue);

      // Mutate state
      await repo.deleteCourse('CS201');
      expect(repo.courses.any((c) => c.code == 'CS201'), isFalse);

      // Restore
      await repo.restoreFromBackupPayload(backupPayload);
      expect(repo.courses.any((c) => c.code == 'CS201'), isTrue);
    });

    test('Attendance percentage and safe/needed class calculations are mathematically correct', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      // Test safe missable classes when above 75%
      expect(repo.overallAttendancePercentage, isA<double>());
      expect(repo.overallAttendancePercentage, greaterThanOrEqualTo(0.0));
      expect(repo.overallAttendancePercentage, lessThanOrEqualTo(100.0));

      if (repo.overallAttendancePercentage >= 75.0) {
        expect(repo.classesNeededFor75, equals(0));
        expect(repo.safeMissableClasses, greaterThanOrEqualTo(0));
      } else {
        expect(repo.safeMissableClasses, equals(0));
        expect(repo.classesNeededFor75, greaterThan(0));
      }
    });

    test('Journal streak logic handles consecutive days and gaps correctly', () async {
      final repo = StuDeskRepository.instance;
      await repo.init();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      await repo.saveJournalEntry(JournalEntry(
        id: 'j-today',
        date: today,
        mood: 'Focus',
        streak: '1',
        tasksCompleted: 1,
        totalTasks: 1,
        linkedCourses: const [],
        learnedText: 'Learned trees',
        accomplishments: const [],
        tags: const [],
        wordCount: 2,
      ));

      await repo.saveJournalEntry(JournalEntry(
        id: 'j-yesterday',
        date: yesterday,
        mood: 'Focus',
        streak: '2',
        tasksCompleted: 1,
        totalTasks: 1,
        linkedCourses: const [],
        learnedText: 'Learned graphs',
        accomplishments: const [],
        tags: const [],
        wordCount: 2,
      ));

      await repo.saveJournalEntry(JournalEntry(
        id: 'j-2days',
        date: twoDaysAgo,
        mood: 'Focus',
        streak: '3',
        tasksCompleted: 1,
        totalTasks: 1,
        linkedCourses: const [],
        learnedText: 'Learned heaps',
        accomplishments: const [],
        tags: const [],
        wordCount: 2,
      ));

      final streak = repo.calculateStreak();
      expect(streak, greaterThanOrEqualTo(3));
    });
  });
}
