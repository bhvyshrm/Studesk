class UserProfile {
  final String id;
  final String username;
  final String name;
  final String preferredName;
  final String email;
  final String college;
  final String course;
  final String semester;
  final String rollNo;
  final String academicYear;
  final String? avatarUrl;
  final String bio;
  final int streakDays;
  final DateTime lastActiveDate;
  final double targetAttendancePercent;
  final int weeklyStudyGoalHours;
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool onboardingCompleted;

  const UserProfile({
    required this.id,
    this.username = '',
    required this.name,
    this.preferredName = '',
    required this.email,
    required this.college,
    required this.course,
    required this.semester,
    required this.rollNo,
    required this.academicYear,
    this.avatarUrl,
    this.bio = '',
    this.streakDays = 0,
    required this.lastActiveDate,
    this.targetAttendancePercent = 75.0,
    this.weeklyStudyGoalHours = 20,
    this.isDarkMode = true,
    this.notificationsEnabled = true,
    this.onboardingCompleted = false,
  });

  String get institution => college;
  String get fullName => name;

  bool get hasUsername => username.trim().isNotEmpty;

  String get effectiveDisplayName {
    if (preferredName.trim().isNotEmpty) return preferredName.trim();
    if (name.trim().isNotEmpty) return name.trim().split(' ').first;
    return 'Student';
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? name,
    String? preferredName,
    String? email,
    String? college,
    String? course,
    String? semester,
    String? rollNo,
    String? academicYear,
    String? avatarUrl,
    String? bio,
    int? streakDays,
    DateTime? lastActiveDate,
    double? targetAttendancePercent,
    int? weeklyStudyGoalHours,
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      preferredName: preferredName ?? this.preferredName,
      email: email ?? this.email,
      college: college ?? this.college,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      rollNo: rollNo ?? this.rollNo,
      academicYear: academicYear ?? this.academicYear,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      targetAttendancePercent:
          targetAttendancePercent ?? this.targetAttendancePercent,
      weeklyStudyGoalHours: weeklyStudyGoalHours ?? this.weeklyStudyGoalHours,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'preferred_name': preferredName,
      'email': email,
      'college': college,
      'course': course,
      'semester': semester,
      'roll_no': rollNo,
      'academic_year': academicYear,
      'avatar_url': avatarUrl,
      'bio': bio,
      'streak_days': streakDays,
      'last_active_date': lastActiveDate.toIso8601String(),
      'target_attendance_percent': targetAttendancePercent,
      'weekly_study_goal_hours': weeklyStudyGoalHours,
      'is_dark_mode': isDarkMode,
      'notifications_enabled': notificationsEnabled,
      'onboarding_completed': onboardingCompleted,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'username': username.trim().isNotEmpty
          ? username.trim().toLowerCase()
          : null,
      'full_name': name,
      'preferred_name': preferredName,
      'avatar_url': avatarUrl ?? '',
      'bio': bio,
      'institution': college,
      'course': course,
      'academic_year': academicYear,
      'semester': semester,
      'onboarding_completed': onboardingCompleted,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'user-default',
      username: json['username'] as String? ?? '',
      name: (json['full_name'] ?? json['name']) as String? ?? '',
      preferredName: json['preferred_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      college: (json['institution'] ?? json['college']) as String? ?? '',
      course: json['course'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      rollNo: json['roll_no'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? '',
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.tryParse(json['last_active_date'] as String) ??
                DateTime.now()
          : DateTime.now(),
      targetAttendancePercent:
          (json['target_attendance_percent'] as num?)?.toDouble() ?? 75.0,
      weeklyStudyGoalHours:
          (json['weekly_study_goal_hours'] as num?)?.toInt() ?? 20,
      isDarkMode: json['is_dark_mode'] as bool? ?? true,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  factory UserProfile.fromSupabase(
    Map<String, dynamic> json, {
    required String fallbackEmail,
    String? fallbackName,
    String? fallbackAvatar,
    String? fallbackUsername,
  }) {
    final rawName = (json['full_name'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (fallbackName ?? '');
    final rawUsername = (json['username'] as String?)?.trim();
    final username = (rawUsername != null && rawUsername.isNotEmpty)
        ? rawUsername
        : (fallbackUsername?.trim() ?? '');
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: username,
      name: name,
      preferredName: json['preferred_name'] as String? ?? '',
      email: fallbackEmail,
      college: json['institution'] as String? ?? '',
      course: json['course'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      rollNo: json['roll_no'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      avatarUrl: (json['avatar_url'] as String?)?.isNotEmpty == true
          ? json['avatar_url'] as String
          : fallbackAvatar,
      bio: json['bio'] as String? ?? '',
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.tryParse(json['last_active_date'] as String) ??
                DateTime.now()
          : DateTime.now(),
      targetAttendancePercent:
          (json['target_attendance_percent'] as num?)?.toDouble() ?? 75.0,
      weeklyStudyGoalHours:
          (json['weekly_study_goal_hours'] as num?)?.toInt() ?? 20,
      isDarkMode: json['is_dark_mode'] as bool? ?? true,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  static UserProfile emptyProfile({
    String id = '',
    String username = '',
    String email = '',
    String name = '',
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      username: username,
      name: name,
      preferredName: name.isNotEmpty ? name.split(' ').first : '',
      email: email,
      college: '',
      course: '',
      semester: '',
      rollNo: '',
      academicYear: '',
      avatarUrl: avatarUrl,
      bio: '',
      streakDays: 0,
      lastActiveDate: DateTime.now(),
      targetAttendancePercent: 75.0,
      weeklyStudyGoalHours: 20,
      isDarkMode: true,
      notificationsEnabled: true,
      onboardingCompleted: false,
    );
  }

  static UserProfile defaultProfile() => emptyProfile(
    id: 'user_current',
    username: '',
    name: 'Student',
    email: 'student@university.edu',
  );
}
