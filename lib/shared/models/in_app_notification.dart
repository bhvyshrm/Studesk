enum NotificationType { reminder, exam, task, event, timetable, system }

class InAppNotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? recordId;
  final bool isRead;
  final bool isDismissed;
  final DateTime createdAt;

  const InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.system,
    this.recordId,
    this.isRead = false,
    this.isDismissed = false,
    required this.createdAt,
  });

  InAppNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? recordId,
    bool? isRead,
    bool? isDismissed,
    DateTime? createdAt,
  }) {
    return InAppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      recordId: recordId ?? this.recordId,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'record_id': recordId,
    'is_read': isRead,
    'is_dismissed': isDismissed,
    'created_at': createdAt.toIso8601String(),
  };

  factory InAppNotificationItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'system';
    final type = NotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NotificationType.system,
    );
    return InAppNotificationItem(
      id:
          json['id'] as String? ??
          'notif_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: type,
      recordId: json['record_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
