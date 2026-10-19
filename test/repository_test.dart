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
  });
}
