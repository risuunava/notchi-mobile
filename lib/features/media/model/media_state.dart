class MediaState {
  const MediaState({
    required this.available,
    required this.title,
    required this.artist,
    required this.album,
    required this.sourceApp,
    required this.playing,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.canSeek,
    required this.artVersion,
  });

  final bool available;
  final String title;
  final String artist;
  final String album;
  final String sourceApp;
  final bool playing;
  final double positionSeconds;
  final double durationSeconds;
  final bool canSeek;
  final int artVersion;

  static const empty = MediaState(
    available: false,
    title: '',
    artist: '',
    album: '',
    sourceApp: '',
    playing: false,
    positionSeconds: 0,
    durationSeconds: 0,
    canSeek: false,
    artVersion: 0,
  );

  factory MediaState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;

    return MediaState(
      available: json['available'] == true,
      title: json['title'] is String ? json['title'] as String : '',
      artist: json['artist'] is String ? json['artist'] as String : '',
      album: json['album'] is String ? json['album'] as String : '',
      sourceApp: json['sourceApp'] is String ? json['sourceApp'] as String : '',
      playing: json['playing'] == true,
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      canSeek: json['canSeek'] == true,
      artVersion: (json['artVersion'] as num?)?.toInt() ?? 0,
    );
  }

  MediaState copyWith({
    bool? available,
    String? title,
    String? artist,
    String? album,
    String? sourceApp,
    bool? playing,
    double? positionSeconds,
    double? durationSeconds,
    bool? canSeek,
    int? artVersion,
  }) {
    return MediaState(
      available: available ?? this.available,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      sourceApp: sourceApp ?? this.sourceApp,
      playing: playing ?? this.playing,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      canSeek: canSeek ?? this.canSeek,
      artVersion: artVersion ?? this.artVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaState &&
          runtimeType == other.runtimeType &&
          available == other.available &&
          title == other.title &&
          artist == other.artist &&
          album == other.album &&
          sourceApp == other.sourceApp &&
          playing == other.playing &&
          positionSeconds == other.positionSeconds &&
          durationSeconds == other.durationSeconds &&
          canSeek == other.canSeek &&
          artVersion == other.artVersion;

  @override
  int get hashCode => Object.hash(
    available,
    title,
    artist,
    album,
    sourceApp,
    playing,
    positionSeconds,
    durationSeconds,
    canSeek,
    artVersion,
  );
}
