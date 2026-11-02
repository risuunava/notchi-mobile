class ShelfUploadResult {
  const ShelfUploadResult({required this.id, required this.name, this.size});

  final String id;
  final String name;
  final int? size;

  factory ShelfUploadResult.fromJson(Map<String, dynamic> json) {
    return ShelfUploadResult(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, if (size != null) 'size': size};
  }
}

class ShelfHistoryEntry {
  const ShelfHistoryEntry({
    required this.id,
    required this.name,
    required this.isText,
    required this.createdAt,
    this.size,
  });

  final String id;
  final String name;
  final bool isText;
  final DateTime createdAt;
  final int? size;

  factory ShelfHistoryEntry.fromUpload(
    ShelfUploadResult result, {
    required bool isText,
  }) {
    return ShelfHistoryEntry(
      id: result.id,
      name: result.name,
      size: result.size,
      isText: isText,
      createdAt: DateTime.now(),
    );
  }

  factory ShelfHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ShelfHistoryEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt(),
      isText: json['isText'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (size != null) 'size': size,
      'isText': isText,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
