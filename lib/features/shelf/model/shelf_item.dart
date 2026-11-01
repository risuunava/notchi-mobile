class ShelfUploadResult {
  const ShelfUploadResult({
    required this.id,
    required this.name,
    this.size,
  });

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
    return {
      'id': id,
      'name': name,
      if (size != null) 'size': size,
    };
  }
}
