class LectureItem {
  final String id;
  final String courseCode;
  final String title;
  final String timeRange;
  final String location;
  final String professor;
  final bool isLive;
  final String? topic;
  final bool isAttended;

  const LectureItem({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.timeRange,
    required this.location,
    required this.professor,
    this.isLive = false,
    this.topic,
    this.isAttended = false,
  });

  LectureItem copyWith({
    String? id,
    String? courseCode,
    String? title,
    String? timeRange,
    String? location,
    String? professor,
    bool? isLive,
    String? topic,
    bool? isAttended,
  }) {
    return LectureItem(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      timeRange: timeRange ?? this.timeRange,
      location: location ?? this.location,
      professor: professor ?? this.professor,
      isLive: isLive ?? this.isLive,
      topic: topic ?? this.topic,
      isAttended: isAttended ?? this.isAttended,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_code': courseCode,
    'title': title,
    'time_range': timeRange,
    'location': location,
    'professor': professor,
    'is_live': isLive,
    'topic': topic,
    'is_attended': isAttended,
  };

  factory LectureItem.fromJson(Map<String, dynamic> json) => LectureItem(
    id: json['id'] as String? ?? 'lec_${DateTime.now().microsecondsSinceEpoch}',
    courseCode: json['course_code'] as String? ?? '',
    title: json['title'] as String? ?? '',
    timeRange: json['time_range'] as String? ?? '',
    location: json['location'] as String? ?? '',
    professor: json['professor'] as String? ?? '',
    isLive: json['is_live'] as bool? ?? false,
    topic: json['topic'] as String?,
    isAttended: json['is_attended'] as bool? ?? false,
  );
}

class TimetableEntry {
  final String id;
  final int dayOfWeek; // 1 (Mon) - 7 (Sun)
  final String startTime;
  final String endTime;
  final String courseCode;
  final String title;
  final String room;
  final String professor;

  const TimetableEntry({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.courseCode,
    required this.title,
    required this.room,
    required this.professor,
  });

  TimetableEntry copyWith({
    String? id,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? courseCode,
    String? title,
    String? room,
    String? professor,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      room: room ?? this.room,
      professor: professor ?? this.professor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'course_code': courseCode,
    'title': title,
    'room': room,
    'professor': professor,
  };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
    id: json['id'] as String? ?? 'tt_${DateTime.now().microsecondsSinceEpoch}',
    dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
    startTime: json['start_time'] as String? ?? '09:00',
    endTime: json['end_time'] as String? ?? '10:00',
    courseCode: json['course_code'] as String? ?? '',
    title: json['title'] as String? ?? '',
    room: json['room'] as String? ?? '',
    professor: json['professor'] as String? ?? '',
  );
}

class ExamItem {
  final String id;
  final String courseCode;
  final String title;
  final DateTime examDate;
  final String room;
  final String syllabusCutoff;
  final int weightagePercent;

  const ExamItem({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.examDate,
    required this.room,
    required this.syllabusCutoff,
    this.weightagePercent = 30,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final difference = examDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return difference < 0 ? 0 : difference;
  }

  ExamItem copyWith({
    String? id,
    String? courseCode,
    String? title,
    DateTime? examDate,
    String? room,
    String? syllabusCutoff,
    int? weightagePercent,
  }) {
    return ExamItem(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      examDate: examDate ?? this.examDate,
      room: room ?? this.room,
      syllabusCutoff: syllabusCutoff ?? this.syllabusCutoff,
      weightagePercent: weightagePercent ?? this.weightagePercent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_code': courseCode,
    'title': title,
    'exam_date': examDate.toIso8601String(),
    'room': room,
    'syllabus_cutoff': syllabusCutoff,
    'weightage_percent': weightagePercent,
  };

  factory ExamItem.fromJson(Map<String, dynamic> json) => ExamItem(
    id:
        json['id'] as String? ??
        'exam_${DateTime.now().microsecondsSinceEpoch}',
    courseCode: json['course_code'] as String? ?? '',
    title: json['title'] as String? ?? '',
    examDate: json['exam_date'] != null
        ? DateTime.tryParse(json['exam_date'] as String) ?? DateTime.now()
        : DateTime.now(),
    room: json['room'] as String? ?? 'Main Hall',
    syllabusCutoff: json['syllabus_cutoff'] as String? ?? 'Units 1-3',
    weightagePercent: (json['weightage_percent'] as num?)?.toInt() ?? 30,
  );
}
