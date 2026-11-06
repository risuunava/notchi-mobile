class VolumeState {
  const VolumeState({required this.level, required this.muted});

  /// Normalized master volume in the range 0.0..1.0.
  final double level;

  final bool muted;

  static const empty = VolumeState(level: 0.5, muted: false);

  factory VolumeState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;

    final rawLevel = json['level'];
    final level = rawLevel is num ? rawLevel.toDouble() : 0.5;

    return VolumeState(
      level: level.clamp(0.0, 1.0),
      muted: json['muted'] == true,
    );
  }

  VolumeState copyWith({double? level, bool? muted}) {
    return VolumeState(level: level ?? this.level, muted: muted ?? this.muted);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeState &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          muted == other.muted;

  @override
  int get hashCode => Object.hash(level, muted);
}
