/// Record for attendance in an individual subject lecture
class SubjectAttendanceRecord {
  final String id;
  final String courseCode;
  final DateTime date;
  final bool isPresent;
  final String? lectureSlot;
  final String? topicDiscussed;

  const SubjectAttendanceRecord({
    required this.id,
    required this.courseCode,
    required this.date,
    required this.isPresent,
    this.lectureSlot,
    this.topicDiscussed,
  });

  SubjectAttendanceRecord copyWith({
    String? id,
    String? courseCode,
    DateTime? date,
    bool? isPresent,
    String? lectureSlot,
    String? topicDiscussed,
  }) {
    return SubjectAttendanceRecord(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      lectureSlot: lectureSlot ?? this.lectureSlot,
      topicDiscussed: topicDiscussed ?? this.topicDiscussed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_code': courseCode,
    'date': date.toIso8601String(),
    'is_present': isPresent,
    'lecture_slot': lectureSlot,
    'topic_discussed': topicDiscussed,
  };

  factory SubjectAttendanceRecord.fromJson(
    Map<String, dynamic> json,
  ) => SubjectAttendanceRecord(
    id: json['id'] as String? ?? 'rec_${DateTime.now().microsecondsSinceEpoch}',
    courseCode: json['course_code'] as String? ?? '',
    date: json['date'] != null
        ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
        : DateTime.now(),
    isPresent: json['is_present'] as bool? ?? true,
    lectureSlot: json['lecture_slot'] as String?,
    topicDiscussed: json['topic_discussed'] as String?,
  );
}

/// Separate record for tracking daily college attendance calendar
class CollegeAttendanceRecord {
  final String id;
  final DateTime date;
  final bool isPresent;
  final String? remarks;

  const CollegeAttendanceRecord({
    required this.id,
    required this.date,
    required this.isPresent,
    this.remarks,
  });

  CollegeAttendanceRecord copyWith({
    String? id,
    DateTime? date,
    bool? isPresent,
    String? remarks,
  }) {
    return CollegeAttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'is_present': isPresent,
    'remarks': remarks,
  };

  factory CollegeAttendanceRecord.fromJson(
    Map<String, dynamic> json,
  ) => CollegeAttendanceRecord(
    id: json['id'] as String? ?? 'col_${DateTime.now().microsecondsSinceEpoch}',
    date: json['date'] != null
        ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
        : DateTime.now(),
    isPresent: json['is_present'] as bool? ?? true,
    remarks: json['remarks'] as String?,
  );
}
