class UserProfile {
  final String id;
  final String name;
  final String email;
  final String college;
  final String course;
  final String semester;
  final String rollNo;
  final String academicYear;
  final int streakDays;
  final DateTime lastActiveDate;
  final double targetAttendancePercent;
  final int weeklyStudyGoalHours;
  final bool isDarkMode;
  final bool notificationsEnabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.college,
    required this.course,
    required this.semester,
    required this.rollNo,
    required this.academicYear,
    this.streakDays = 14,
    required this.lastActiveDate,
    this.targetAttendancePercent = 85.0,
    this.weeklyStudyGoalHours = 20,
    this.isDarkMode = true,
    this.notificationsEnabled = true,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? college,
    String? course,
    String? semester,
    String? rollNo,
    String? academicYear,
    int? streakDays,
    DateTime? lastActiveDate,
    double? targetAttendancePercent,
    int? weeklyStudyGoalHours,
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      college: college ?? this.college,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      rollNo: rollNo ?? this.rollNo,
      academicYear: academicYear ?? this.academicYear,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      targetAttendancePercent: targetAttendancePercent ?? this.targetAttendancePercent,
      weeklyStudyGoalHours: weeklyStudyGoalHours ?? this.weeklyStudyGoalHours,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'college': college,
      'course': course,
      'semester': semester,
      'roll_no': rollNo,
      'academic_year': academicYear,
      'streak_days': streakDays,
      'last_active_date': lastActiveDate.toIso8601String(),
      'target_attendance_percent': targetAttendancePercent,
      'weekly_study_goal_hours': weeklyStudyGoalHours,
      'is_dark_mode': isDarkMode,
      'notifications_enabled': notificationsEnabled,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'user-default',
      name: json['name'] as String? ?? 'Alex Chen',
      email: json['email'] as String? ?? 'alex.chen@university.edu',
      college: json['college'] as String? ?? 'Dept of Computer Science',
      course: json['course'] as String? ?? 'B.Tech Computer Science',
      semester: json['semester'] as String? ?? 'Semester 4',
      rollNo: json['roll_no'] as String? ?? '22CS1049',
      academicYear: json['academic_year'] as String? ?? 'Year 2',
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 14,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.tryParse(json['last_active_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      targetAttendancePercent: (json['target_attendance_percent'] as num?)?.toDouble() ?? 85.0,
      weeklyStudyGoalHours: (json['weekly_study_goal_hours'] as num?)?.toInt() ?? 20,
      isDarkMode: json['is_dark_mode'] as bool? ?? true,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  static UserProfile defaultProfile() {
    return UserProfile(
      id: 'demo-user-1',
      name: 'Alex Chen',
      email: 'alex.chen@university.edu',
      college: 'Dept of Computer Science',
      course: 'B.Tech Computer Science & Engineering',
      semester: 'Semester 4',
      rollNo: '22CS1049',
      academicYear: 'Year 2',
      streakDays: 14,
      lastActiveDate: DateTime.now(),
      targetAttendancePercent: 85.0,
      weeklyStudyGoalHours: 20,
      isDarkMode: true,
      notificationsEnabled: true,
    );
  }
}
