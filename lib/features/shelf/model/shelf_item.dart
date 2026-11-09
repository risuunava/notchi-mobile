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
    this.filePath,
    this.content,
    this.isIncoming = false,
  });

  final String id;
  final String name;
  final bool isText;
  final DateTime createdAt;
  final int? size;
  final String? filePath;
  final String? content;
  final bool isIncoming;

  factory ShelfHistoryEntry.fromUpload(
    ShelfUploadResult result, {
    required bool isText,
    String? filePath,
    String? content,
    bool isIncoming = false,
  }) {
    return ShelfHistoryEntry(
      id: result.id,
      name: result.name,
      size: result.size,
      isText: isText,
      createdAt: DateTime.now(),
      filePath: filePath,
      content: content,
      isIncoming: isIncoming,
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
      filePath: json['filePath'] as String?,
      content: json['content'] as String?,
      isIncoming: json['isIncoming'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (size != null) 'size': size,
      'isText': isText,
      'createdAt': createdAt.toIso8601String(),
      if (filePath != null) 'filePath': filePath,
      if (content != null) 'content': content,
      if (isIncoming) 'isIncoming': true,
    };
  }
}
