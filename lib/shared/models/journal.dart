class JournalEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String streak;
  final int tasksCompleted;
  final int totalTasks;
  final List<String> linkedCourses;
  final String learnedText;
  final String? codeSnippet;
  final List<String> accomplishments;
  final String? blocker;
  final List<String> tags;
  final int wordCount;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.streak,
    this.tasksCompleted = 0,
    this.totalTasks = 0,
    this.linkedCourses = const [],
    required this.learnedText,
    this.codeSnippet,
    this.accomplishments = const [],
    this.blocker,
    this.tags = const [],
    required this.wordCount,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? mood,
    String? streak,
    int? tasksCompleted,
    int? totalTasks,
    List<String>? linkedCourses,
    String? learnedText,
    String? codeSnippet,
    List<String>? accomplishments,
    String? blocker,
    List<String>? tags,
    int? wordCount,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      streak: streak ?? this.streak,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      totalTasks: totalTasks ?? this.totalTasks,
      linkedCourses: linkedCourses ?? this.linkedCourses,
      learnedText: learnedText ?? this.learnedText,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      accomplishments: accomplishments ?? this.accomplishments,
      blocker: blocker ?? this.blocker,
      tags: tags ?? this.tags,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mood': mood,
    'streak': streak,
    'tasks_completed': tasksCompleted,
    'total_tasks': totalTasks,
    'linked_courses': linkedCourses,
    'learned_text': learnedText,
    'code_snippet': codeSnippet,
    'accomplishments': accomplishments,
    'blocker': blocker,
    'tags': tags,
    'word_count': wordCount,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id:
          json['id'] as String? ??
          'jrn_${DateTime.now().microsecondsSinceEpoch}',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      mood: json['mood'] as String? ?? 'Deep Focus',
      streak: json['streak'] as String? ?? '14 Days',
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      linkedCourses:
          (json['linked_courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      learnedText: json['learned_text'] as String? ?? '',
      codeSnippet: json['code_snippet'] as String?,
      accomplishments:
          (json['accomplishments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      blocker: json['blocker'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
    );
  }
}
