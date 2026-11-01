import '../../../core/network/protocol.dart';

sealed class ConnectionStatus {
  const ConnectionStatus();
}

class ConnectionIdle extends ConnectionStatus {
  const ConnectionIdle();
}

class ConnectionConnecting extends ConnectionStatus {
  const ConnectionConnecting();
}

class ConnectionConnected extends ConnectionStatus {
  const ConnectionConnected({this.hello});

  final PcHello? hello;
}

class ConnectionReconnecting extends ConnectionStatus {
  const ConnectionReconnecting({required this.attempt, required this.delay});

  final int attempt;
  final Duration delay;
}

enum ConnectionStopReason { revoked, disabled, unauthorized }

class ConnectionStopped extends ConnectionStatus {
  const ConnectionStopped(this.reason);

  final ConnectionStopReason reason;
}
