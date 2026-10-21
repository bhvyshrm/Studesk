enum AcademicFileType { pdf, image, doc, note }

class AcademicNote {
  final String id;
  final String title;
  final String subjectCode;
  final AcademicFileType fileType;
  final String? fileUrl;
  final String content;
  final String fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademicNote({
    required this.id,
    required this.title,
    required this.subjectCode,
    this.fileType = AcademicFileType.note,
    this.fileUrl,
    this.content = '',
    this.fileSize = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  AcademicNote copyWith({
    String? id,
    String? title,
    String? subjectCode,
    AcademicFileType? fileType,
    String? fileUrl,
    String? content,
    String? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicNote(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectCode: subjectCode ?? this.subjectCode,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      content: content ?? this.content,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject_code': subjectCode,
    'file_type': fileType.name,
    'file_url': fileUrl,
    'content': content,
    'file_size': fileSize,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory AcademicNote.fromJson(Map<String, dynamic> json) {
    final typeStr = json['file_type'] as String? ?? 'note';
    final type = AcademicFileType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AcademicFileType.note,
    );
    return AcademicNote(
      id:
          json['id'] as String? ??
          'note_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? 'General',
      fileType: type,
      fileUrl: json['file_url'] as String?,
      content: json['content'] as String? ?? '',
      fileSize: json['file_size'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
