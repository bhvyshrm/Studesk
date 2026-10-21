import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'attendance.dart';
import 'course.dart';
import 'journal.dart';
import 'resource.dart';
import 'task.dart';
import 'timetable.dart';
import 'user_profile.dart';

enum RestoreConflictStrategy { overwrite, mergeSkipExisting, mergeKeepNewer }

class BackupMetadata {
  final String appVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final String deviceName;
  final int coursesCount;
  final int tasksCount;
  final int resourcesCount;
  final int journalsCount;
  final int attendanceRecordsCount;
  final String dataChecksum;

  const BackupMetadata({
    required this.appVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.deviceName,
    required this.coursesCount,
    required this.tasksCount,
    required this.resourcesCount,
    required this.journalsCount,
    required this.attendanceRecordsCount,
    required this.dataChecksum,
  });

  Map<String, dynamic> toJson() => {
    'app_version': appVersion,
    'schema_version': schemaVersion,
    'exported_at': exportedAt.toIso8601String(),
    'device_name': deviceName,
    'courses_count': coursesCount,
    'tasks_count': tasksCount,
    'resources_count': resourcesCount,
    'journals_count': journalsCount,
    'attendance_records_count': attendanceRecordsCount,
    'data_checksum': dataChecksum,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    appVersion: json['app_version'] as String? ?? '1.0.0',
    schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    exportedAt: json['exported_at'] != null
        ? DateTime.tryParse(json['exported_at'] as String) ?? DateTime.now()
        : DateTime.now(),
    deviceName: json['device_name'] as String? ?? 'StuDesk Device',
    coursesCount: (json['courses_count'] as num?)?.toInt() ?? 0,
    tasksCount: (json['tasks_count'] as num?)?.toInt() ?? 0,
    resourcesCount: (json['resources_count'] as num?)?.toInt() ?? 0,
    journalsCount: (json['journals_count'] as num?)?.toInt() ?? 0,
    attendanceRecordsCount:
        (json['attendance_records_count'] as num?)?.toInt() ?? 0,
    dataChecksum: json['data_checksum'] as String? ?? '',
  );
}

class StuDeskBackupPayload {
  static const int currentSchemaVersion = 1;

  final BackupMetadata metadata;
  final UserProfile profile;
  final List<Course> courses;
  final List<TaskItem> tasks;
  final List<LibraryResource> resources;
  final List<JournalEntry> journals;
  final List<SubjectAttendanceRecord> subjectAttendance;
  final List<CollegeAttendanceRecord> collegeAttendance;
  final List<TimetableEntry> timetable;
  final List<ExamItem> exams;

  const StuDeskBackupPayload({
    required this.metadata,
    required this.profile,
    required this.courses,
    required this.tasks,
    required this.resources,
    required this.journals,
    required this.subjectAttendance,
    required this.collegeAttendance,
    required this.timetable,
    required this.exams,
  });

  static String generateChecksum(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'profile': profile.toJson(),
    'courses': courses.map((c) => c.toJson()).toList(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'resources': resources.map((r) => r.toJson()).toList(),
    'journals': journals.map((j) => j.toJson()).toList(),
    'subject_attendance': subjectAttendance.map((a) => a.toJson()).toList(),
    'college_attendance': collegeAttendance.map((a) => a.toJson()).toList(),
    'timetable': timetable.map((t) => t.toJson()).toList(),
    'exams': exams.map((e) => e.toJson()).toList(),
  };

  factory StuDeskBackupPayload.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('metadata') || !json.containsKey('profile')) {
      throw const FormatException(
        'Invalid StuDesk backup format: missing metadata or profile.',
      );
    }

    final meta = BackupMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>,
    );
    if (meta.schemaVersion > currentSchemaVersion) {
      throw FormatException(
        'Incompatible backup schema v${meta.schemaVersion}. Current app supports up to v$currentSchemaVersion.',
      );
    }

    final profile = UserProfile.fromJson(
      json['profile'] as Map<String, dynamic>,
    );
    final courses = (json['courses'] as List<dynamic>? ?? [])
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
    final tasks = (json['tasks'] as List<dynamic>? ?? [])
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final resources = (json['resources'] as List<dynamic>? ?? [])
        .map((e) => LibraryResource.fromJson(e as Map<String, dynamic>))
        .toList();
    final journals = (json['journals'] as List<dynamic>? ?? [])
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final subjectAttendance =
        (json['subject_attendance'] as List<dynamic>? ?? [])
            .map(
              (e) =>
                  SubjectAttendanceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    final collegeAttendance =
        (json['college_attendance'] as List<dynamic>? ?? [])
            .map(
              (e) =>
                  CollegeAttendanceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    final timetable = (json['timetable'] as List<dynamic>? ?? [])
        .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final exams = (json['exams'] as List<dynamic>? ?? [])
        .map((e) => ExamItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return StuDeskBackupPayload(
      metadata: meta,
      profile: profile,
      courses: courses,
      tasks: tasks,
      resources: resources,
      journals: journals,
      subjectAttendance: subjectAttendance,
      collegeAttendance: collegeAttendance,
      timetable: timetable,
      exams: exams,
    );
  }
}
