class EventItem {
  final String id;
  final String title;
  final DateTime eventDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? notes;
  final bool hasReminder;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventItem({
    required this.id,
    required this.title,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.location,
    this.notes,
    this.hasReminder = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  EventItem copyWith({
    String? id,
    String? title,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    String? location,
    String? notes,
    bool? hasReminder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      hasReminder: hasReminder ?? this.hasReminder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'event_date': eventDate.toIso8601String(),
    'start_time': startTime,
    'end_time': endTime,
    'location': location,
    'notes': notes,
    'has_reminder': hasReminder,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory EventItem.fromJson(Map<String, dynamic> json) => EventItem(
    id:
        json['id'] as String? ??
        'event_${DateTime.now().microsecondsSinceEpoch}',
    title: json['title'] as String? ?? '',
    eventDate: json['event_date'] != null
        ? DateTime.tryParse(json['event_date'] as String) ?? DateTime.now()
        : DateTime.now(),
    startTime: json['start_time'] as String?,
    endTime: json['end_time'] as String?,
    location: json['location'] as String?,
    notes: json['notes'] as String?,
    hasReminder: json['has_reminder'] as bool? ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );
}
