import '../../../core/storage/secure_store.dart';

class ConnectionConfig {
  const ConnectionConfig({
    this.heartbeatInterval = const Duration(seconds: 20),
    this.pongTimeout = const Duration(seconds: 10),
    this.maxBackoff = const Duration(seconds: 30),
  });

  final Duration heartbeatInterval;
  final Duration pongTimeout;
  final Duration maxBackoff;

  Uri uriFor(SavedSession session) {
    return Uri(
      scheme: 'ws',
      host: session.host,
      port: session.port,
      path: '/ws',
    );
  }

  Map<String, String> headersFor(SavedSession session) {
    return {'Authorization': 'Bearer ${session.sessionToken}'};
  }

  Duration backoffFor(int attempt) {
    var seconds = 1 << attempt.clamp(0, 5);
    if (seconds > maxBackoff.inSeconds) seconds = maxBackoff.inSeconds;
    if (seconds < 1) seconds = 1;
    return Duration(seconds: seconds);
  }
}
