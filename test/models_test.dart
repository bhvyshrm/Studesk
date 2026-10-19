import 'package:flutter_test/flutter_test.dart';
import 'package:studesk/shared/models/models.dart';

void main() {
  group('Course & Syllabus Model Tests', () {
    test('Attendance percentage calculation avoids division by zero', () {
      const courseZero = Course(
        code: 'CS100',
        title: 'Intro CS',
        professor: 'Dr. Test',
        department: 'CS',
        schedule: 'MWF',
        location: '101',
        credits: 3,
        attendedLectures: 0,
        totalLectures: 0,
      );
      expect(courseZero.attendancePercent, 0.0);

      const courseValid = Course(
        code: 'CS201',
        title: 'DSA',
        professor: 'Dr. Vance',
        department: 'CS',
        schedule: 'MWF',
        location: 'B-204',
        credits: 4,
        attendedLectures: 18,
        totalLectures: 20,
      );
      expect(courseValid.attendancePercent, 90.0);
    });

    test('Syllabus percentage is accurately calculated from units and topics', () {
      const unit1 = CourseUnit(
        unitNumber: 1,
        title: 'Trees',
        status: UnitStatus.completed,
        topics: [
          UnitTopic(id: 't1', title: 'BST', date: 'Oct 1', subtitle: 'Search', isCompleted: true),
          UnitTopic(id: 't2', title: 'AVL', date: 'Oct 3', subtitle: 'Balancing', isCompleted: true),
        ],
      );

      const unit2 = CourseUnit(
        unitNumber: 2,
        title: 'Graphs',
        status: UnitStatus.current,
        topics: [
          UnitTopic(id: 't3', title: 'BFS', date: 'Oct 5', subtitle: 'Queue', isCompleted: true),
          UnitTopic(id: 't4', title: 'DFS', date: 'Oct 7', subtitle: 'Stack', isCompleted: false),
        ],
      );

      final course = const Course(
        code: 'CS201',
        title: 'DSA',
        professor: 'Dr. Vance',
        department: 'CS',
        schedule: 'MWF',
        location: 'B-204',
        credits: 4,
        attendedLectures: 18,
        totalLectures: 20,
      ).copyWith(units: [unit1, unit2]);

      expect(course.completedTopics, 3);
      expect(course.totalTopics, 4);
      expect(course.syllabusPercent, 75.0);
    });

    test('Course JSON serialization round-trip retains all data', () {
      const course = Course(
        code: 'CS204',
        title: 'Operating Systems',
        professor: 'Prof. Helen',
        department: 'CS',
        schedule: 'Tue, Thu',
        location: 'Lab 2',
        credits: 4,
        attendedLectures: 19,
        totalLectures: 25,
        grade: 'B+',
        standing: 'Warning',
        lastTopic: 'Semaphores',
        isWarning: true,
      );

      final json = course.toJson();
      final restored = Course.fromJson(json);

      expect(restored.code, course.code);
      expect(restored.title, course.title);
      expect(restored.attendedLectures, 19);
      expect(restored.totalLectures, 25);
      expect(restored.attendancePercent, 76.0);
      expect(restored.isWarning, isTrue);
    });
  });

  group('Attendance Model Tests', () {
    test('Subject attendance and College attendance are distinctly preserved', () {
      final now = DateTime.now();
      final subjectRec = SubjectAttendanceRecord(
        id: 'sub-1',
        courseCode: 'CS201',
        date: now,
        isPresent: true,
        lectureSlot: '10:15 - 11:45 AM',
        topicDiscussed: 'Red Black Trees',
      );

      final collegeRec = CollegeAttendanceRecord(
        id: 'col-1',
        date: now,
        isPresent: true,
        remarks: 'Attended full college day',
      );

      final subJson = subjectRec.toJson();
      final colJson = collegeRec.toJson();

      final restoredSub = SubjectAttendanceRecord.fromJson(subJson);
      final restoredCol = CollegeAttendanceRecord.fromJson(colJson);

      expect(restoredSub.courseCode, 'CS201');
      expect(restoredSub.topicDiscussed, 'Red Black Trees');
      expect(restoredCol.remarks, 'Attended full college day');
    });
  });

  group('Backup Payload & Checksum Tests', () {
    test('Checksum validation identifies corrupted backups', () {
      const payloadString = '{"app_version":"1.0.0","data":"clean"}';
      final checksum = StuDeskBackupPayload.generateChecksum(payloadString);
      expect(checksum.isNotEmpty, isTrue);

      const modifiedPayload = '{"app_version":"1.0.0","data":"corrupted"}';
      final modifiedChecksum = StuDeskBackupPayload.generateChecksum(modifiedPayload);
      expect(checksum != modifiedChecksum, isTrue);
    });

    test('UserProfile defaults and serialization behave properly', () {
      final profile = UserProfile.defaultProfile();
      expect(profile.name, 'Alex Chen');
      expect(profile.streakDays, 14);

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.name, 'Alex Chen');
      expect(restored.rollNo, '22CS1049');
      expect(restored.targetAttendancePercent, 85.0);
    });
  });
}
