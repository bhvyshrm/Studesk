class LibraryCollection {
  final String id;
  final String name;
  final String description;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  LibraryCollection({
    required this.id,
    required this.name,
    this.description = '',
    this.colorHex = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  LibraryCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibraryCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color_hex': colorHex,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory LibraryCollection.fromJson(Map<String, dynamic> json) => LibraryCollection(
        id: json['id'] as String? ?? 'col_${DateTime.now().microsecondsSinceEpoch}',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        colorHex: json['color_hex'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );
}
