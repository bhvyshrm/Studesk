class ReminderItem {
  final String id;
  final String text;
  final DateTime reminderTime;
  final String? repeatRule; // 'none', 'daily', 'weekly'
  final String? linkedId;
  final String? linkedType; // 'task', 'exam', 'event'
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderItem({
    required this.id,
    required this.text,
    required this.reminderTime,
    this.repeatRule,
    this.linkedId,
    this.linkedType,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  ReminderItem copyWith({
    String? id,
    String? text,
    DateTime? reminderTime,
    String? repeatRule,
    String? linkedId,
    String? linkedType,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      text: text ?? this.text,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatRule: repeatRule ?? this.repeatRule,
      linkedId: linkedId ?? this.linkedId,
      linkedType: linkedType ?? this.linkedType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'reminder_time': reminderTime.toIso8601String(),
    'repeat_rule': repeatRule,
    'linked_id': linkedId,
    'linked_type': linkedType,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'] as String? ?? 'rem_${DateTime.now().microsecondsSinceEpoch}',
    text: json['text'] as String? ?? '',
    reminderTime: json['reminder_time'] != null
        ? DateTime.tryParse(json['reminder_time'] as String) ?? DateTime.now()
        : DateTime.now(),
    repeatRule: json['repeat_rule'] as String?,
    linkedId: json['linked_id'] as String?,
    linkedType: json['linked_type'] as String?,
    isCompleted: json['is_completed'] as bool? ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );
}
