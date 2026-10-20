enum ResourceType { video, playlist, link, doc, pdf, note, bookmark }

class LibraryResource {
  final String id;
  final String title;
  final ResourceType type;
  final String subjectTag;
  final String? url;
  final String? noteContent;
  final String? description;
  final String? collectionId;
  final String? duration;
  final String? metaInfo;
  final String? channel;
  final bool isBookmarked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LibraryResource({
    required this.id,
    required this.title,
    required this.type,
    required this.subjectTag,
    this.url,
    this.noteContent,
    this.description,
    this.collectionId,
    this.duration,
    this.metaInfo,
    this.channel,
    this.isBookmarked = false,
    this.createdAt,
    this.updatedAt,
  });

  DateTime get effectiveCreatedAt => createdAt ?? DateTime.now();

  bool get isYouTube =>
      url != null &&
      (url!.contains('youtube.com') || url!.contains('youtu.be'));

  LibraryResource copyWith({
    String? id,
    String? title,
    ResourceType? type,
    String? subjectTag,
    String? url,
    String? noteContent,
    String? description,
    String? collectionId,
    String? duration,
    String? metaInfo,
    String? channel,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibraryResource(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      subjectTag: subjectTag ?? this.subjectTag,
      url: url ?? this.url,
      noteContent: noteContent ?? this.noteContent,
      description: description ?? this.description,
      collectionId: collectionId ?? this.collectionId,
      duration: duration ?? this.duration,
      metaInfo: metaInfo ?? this.metaInfo,
      channel: channel ?? this.channel,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'subject_tag': subjectTag,
        'url': url,
        'note_content': noteContent,
        'description': description,
        'collection_id': collectionId,
        'duration': duration,
        'meta_info': metaInfo,
        'channel': channel,
        'is_bookmarked': isBookmarked,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory LibraryResource.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'note';
    final type = ResourceType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ResourceType.note,
    );
    return LibraryResource(
      id: json['id'] as String? ?? 'res_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      type: type,
      subjectTag: json['subject_tag'] as String? ?? 'General',
      url: json['url'] as String?,
      noteContent: json['note_content'] as String?,
      description: json['description'] as String?,
      collectionId: json['collection_id'] as String?,
      duration: json['duration'] as String?,
      metaInfo: json['meta_info'] as String?,
      channel: json['channel'] as String?,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
