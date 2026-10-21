enum TaskPriority { high, academic, review, normal }

class TaskItem {
  final String id;
  final String title;
  final TaskPriority priority;
  final String? dueTime;
  final DateTime? dueDate;
  final String categoryTag;
  final String? detail;
  final String? courseCode;
  final bool isRecurring;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    this.dueTime,
    this.dueDate,
    required this.categoryTag,
    this.detail,
    this.courseCode,
    this.isRecurring = false,
    this.isCompleted = false,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    String? dueTime,
    DateTime? dueDate,
    String? categoryTag,
    String? detail,
    String? courseCode,
    bool? isRecurring,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueTime: dueTime ?? this.dueTime,
      dueDate: dueDate ?? this.dueDate,
      categoryTag: categoryTag ?? this.categoryTag,
      detail: detail ?? this.detail,
      courseCode: courseCode ?? this.courseCode,
      isRecurring: isRecurring ?? this.isRecurring,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'priority': priority.name,
    'due_time': dueTime,
    'due_date': dueDate?.toIso8601String(),
    'category_tag': categoryTag,
    'detail': detail,
    'course_code': courseCode,
    'is_recurring': isRecurring,
    'is_completed': isCompleted,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final priorityStr = json['priority'] as String? ?? 'normal';
    final priority = TaskPriority.values.firstWhere(
      (e) => e.name == priorityStr,
      orElse: () => TaskPriority.normal,
    );
    return TaskItem(
      id:
          json['id'] as String? ??
          'task_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      priority: priority,
      dueTime: json['due_time'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      categoryTag: json['category_tag'] as String? ?? 'General',
      detail: json['detail'] as String?,
      courseCode: json['course_code'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}
