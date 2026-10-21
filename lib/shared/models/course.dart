// ignore_for_file: prefer_initializing_formals
enum UnitStatus { completed, current, upcoming }

class UnitTopic {
  final String id;
  final String title;
  final String date;
  final String subtitle;
  final bool isCompleted;

  const UnitTopic({
    this.id = '',
    required this.title,
    required this.date,
    required this.subtitle,
    this.isCompleted = false,
  });

  UnitTopic copyWith({
    String? id,
    String? title,
    String? date,
    String? subtitle,
    bool? isCompleted,
  }) {
    return UnitTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.isEmpty ? 'topic_${DateTime.now().microsecondsSinceEpoch}' : id,
    'title': title,
    'date': date,
    'subtitle': subtitle,
    'is_completed': isCompleted,
  };

  factory UnitTopic.fromJson(Map<String, dynamic> json) => UnitTopic(
    id:
        json['id'] as String? ??
        'topic_${DateTime.now().microsecondsSinceEpoch}',
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    isCompleted: json['is_completed'] as bool? ?? false,
  );
}

class CourseUnit {
  final int unitNumber;
  final String title;
  final UnitStatus status;
  final int? _completedTopics;
  final int? _totalTopics;
  final List<UnitTopic> topics;

  const CourseUnit({
    required this.unitNumber,
    required this.title,
    required this.status,
    int? completedTopics,
    int? totalTopics,
    this.topics = const [],
  }) : _completedTopics = completedTopics,
       _totalTopics = totalTopics;

  int get completedTopics => topics.isNotEmpty
      ? topics.where((t) => t.isCompleted).length
      : (_completedTopics ?? 0);

  int get totalTopics =>
      topics.isNotEmpty ? topics.length : (_totalTopics ?? 0);

  double get completionPercent =>
      totalTopics == 0 ? 0.0 : ((completedTopics / totalTopics) * 100.0);

  CourseUnit copyWith({
    int? unitNumber,
    String? title,
    UnitStatus? status,
    int? completedTopics,
    int? totalTopics,
    List<UnitTopic>? topics,
  }) {
    return CourseUnit(
      unitNumber: unitNumber ?? this.unitNumber,
      title: title ?? this.title,
      status: status ?? this.status,
      completedTopics: completedTopics ?? _completedTopics,
      totalTopics: totalTopics ?? _totalTopics,
      topics: topics ?? this.topics,
    );
  }

  Map<String, dynamic> toJson() => {
    'unit_number': unitNumber,
    'title': title,
    'status': status.name,
    'completed_topics': completedTopics,
    'total_topics': totalTopics,
    'topics': topics.map((t) => t.toJson()).toList(),
  };

  factory CourseUnit.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'upcoming';
    final unitStatus = UnitStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => UnitStatus.upcoming,
    );
    final rawTopics = json['topics'] as List<dynamic>? ?? [];
    return CourseUnit(
      unitNumber: (json['unit_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      status: unitStatus,
      completedTopics: (json['completed_topics'] as num?)?.toInt(),
      totalTopics: (json['total_topics'] as num?)?.toInt(),
      topics: rawTopics
          .map((t) => UnitTopic.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Course {
  final String code;
  final String title;
  final String professor;
  final String department;
  final String schedule;
  final String location;
  final int credits;
  final int attendedLectures;
  final int totalLectures;
  final double? _attendancePercent;
  final double? _syllabusPercent;
  final int? _completedTopics;
  final int? _totalTopics;
  final String grade;
  final String standing;
  final String lastTopic;
  final bool isWarning;
  final List<CourseUnit> units;

  const Course({
    required this.code,
    required this.title,
    required this.professor,
    required this.department,
    required this.schedule,
    required this.location,
    required this.credits,
    required this.attendedLectures,
    required this.totalLectures,
    double? attendancePercent,
    double? syllabusPercent,
    int? completedTopics,
    int? totalTopics,
    this.grade = 'A',
    this.standing = 'Safe',
    this.lastTopic = '',
    this.isWarning = false,
    this.units = const [],
  }) : _attendancePercent = attendancePercent,
       _syllabusPercent = syllabusPercent,
       _completedTopics = completedTopics,
       _totalTopics = totalTopics;

  /// Safe calculation avoiding division by zero
  double get attendancePercent =>
      _attendancePercent ??
      (totalLectures == 0 ? 0.0 : ((attendedLectures / totalLectures) * 100.0));

  int get completedTopics => units.isNotEmpty
      ? units.fold(0, (acc, unit) => acc + unit.completedTopics)
      : (_completedTopics ?? 0);

  int get totalTopics => units.isNotEmpty
      ? units.fold(0, (acc, unit) => acc + unit.totalTopics)
      : (_totalTopics ?? 0);

  int get remainingTopics => (totalTopics - completedTopics).clamp(0, 9999);

  double get syllabusPercent => units.isNotEmpty
      ? (totalTopics == 0 ? 0.0 : ((completedTopics / totalTopics) * 100.0))
      : (_syllabusPercent ??
            (totalTopics == 0
                ? 0.0
                : ((completedTopics / totalTopics) * 100.0)));

  Course copyWith({
    String? code,
    String? title,
    String? professor,
    String? department,
    String? schedule,
    String? location,
    int? credits,
    int? attendedLectures,
    int? totalLectures,
    double? attendancePercent,
    double? syllabusPercent,
    int? completedTopics,
    int? totalTopics,
    String? grade,
    String? standing,
    String? lastTopic,
    bool? isWarning,
    List<CourseUnit>? units,
  }) {
    return Course(
      code: code ?? this.code,
      title: title ?? this.title,
      professor: professor ?? this.professor,
      department: department ?? this.department,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      credits: credits ?? this.credits,
      attendedLectures: attendedLectures ?? this.attendedLectures,
      totalLectures: totalLectures ?? this.totalLectures,
      attendancePercent: attendancePercent ?? _attendancePercent,
      syllabusPercent: syllabusPercent ?? _syllabusPercent,
      completedTopics: completedTopics ?? _completedTopics,
      totalTopics: totalTopics ?? _totalTopics,
      grade: grade ?? this.grade,
      standing: standing ?? this.standing,
      lastTopic: lastTopic ?? this.lastTopic,
      isWarning: isWarning ?? this.isWarning,
      units: units ?? this.units,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'professor': professor,
    'department': department,
    'schedule': schedule,
    'location': location,
    'credits': credits,
    'attended_lectures': attendedLectures,
    'total_lectures': totalLectures,
    'attendance_percent': attendancePercent,
    'syllabus_percent': syllabusPercent,
    'completed_topics': completedTopics,
    'total_topics': totalTopics,
    'grade': grade,
    'standing': standing,
    'last_topic': lastTopic,
    'is_warning': isWarning,
    'units': units.map((u) => u.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    final rawUnits = json['units'] as List<dynamic>? ?? [];
    return Course(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      professor: json['professor'] as String? ?? '',
      department: json['department'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      location: json['location'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      attendedLectures: (json['attended_lectures'] as num?)?.toInt() ?? 0,
      totalLectures: (json['total_lectures'] as num?)?.toInt() ?? 0,
      attendancePercent: (json['attendance_percent'] as num?)?.toDouble(),
      syllabusPercent: (json['syllabus_percent'] as num?)?.toDouble(),
      completedTopics: (json['completed_topics'] as num?)?.toInt(),
      totalTopics: (json['total_topics'] as num?)?.toInt(),
      grade: json['grade'] as String? ?? 'A',
      standing: json['standing'] as String? ?? 'Safe',
      lastTopic: json['last_topic'] as String? ?? '',
      isWarning: json['is_warning'] as bool? ?? false,
      units: rawUnits
          .map((u) => CourseUnit.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }
}
