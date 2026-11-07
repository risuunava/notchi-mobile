import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/protocol.dart';
import '../../../core/network/ws_connector.dart';
import '../../../core/storage/secure_store.dart';
import 'connection_config.dart';
import 'connection_providers.dart';
import 'connection_status.dart';

class ConnectionController extends Notifier<ConnectionStatus> {
  final StreamController<WsMessage> _messages =
      StreamController<WsMessage>.broadcast();

  WsConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _pongTimer;
  SavedSession? _session;
  int _attempt = 0;
  int _generation = 0;
  int? _runningGeneration;
  bool _manualStop = true;

  Stream<WsMessage> get messages => _messages.stream;

  @override
  ConnectionStatus build() {
    ref.onDispose(() {
      _manualStop = true;
      _generation++;
      _detach();
      unawaited(_messages.close());
    });
    return const ConnectionIdle();
  }

  void connect(SavedSession session) {
    final sameSession =
        _session?.sessionToken == session.sessionToken &&
        _session?.host == session.host &&
        _session?.port == session.port;
    if (sameSession && (_connection != null || _runningGeneration != null)) {
      return;
    }

    _generation++;
    _manualStop = true;
    _detach();

    _session = session;
    _attempt = 0;
    _manualStop = false;

    unawaited(_run(_generation));
  }

  /// Force-drops the current connection and immediately retries.
  /// Safe to call from any connection state — a no-op if no session is saved.
  void reconnect() {
    final session = _session;
    if (session == null) return;

    _generation++;
    _manualStop = true;
    _detach();

    _attempt = 0;
    _manualStop = false;
    unawaited(_run(_generation));
  }

  void disconnect([ConnectionStopReason? reason]) {
    final keepStopped = reason == null && state is ConnectionStopped;

    _generation++;
    _manualStop = true;
    _detach();
    _session = null;
    _attempt = 0;

    if (reason != null) {
      state = ConnectionStopped(reason);
    } else if (!keepStopped) {
      state = const ConnectionIdle();
    }
  }

  bool send(WsMessage message) {
    final connection = _connection;
    if (connection == null) return false;
    try {
      connection.send(message.encode());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _run(int generation) async {
    if (_runningGeneration == generation) return;
    _runningGeneration = generation;

    try {
      while (!_manualStop && generation == _generation) {
        final session = _session;
        if (session == null) return;

        if (_attempt > 0) {
          final delay = _config.backoffFor(_attempt - 1);
          state = ConnectionReconnecting(attempt: _attempt, delay: delay);
          await Future<void>.delayed(delay);
          if (_manualStop || generation != _generation) return;
        } else {
          state = const ConnectionConnecting();
        }

        try {
          final connection = await ref
              .read(wsConnectorProvider)
              .connect(
                _config.uriFor(session),
                headers: _config.headersFor(session),
              );

          if (_manualStop || generation != _generation) {
            await _safeClose(connection);
            return;
          }

          _connection = connection;
          _attempt = 0;
          state = const ConnectionConnected();
          _subscription = connection.messages.listen(
            (raw) => _onMessage(raw, generation),
            onError: (Object _) => _onClosed(generation),
            onDone: () => _onClosed(generation),
          );
          _startHeartbeat(generation);
          return;
        } catch (error) {
          if (_manualStop || generation != _generation) return;
          if (_isUnauthorized(error)) {
            _stopWith(ConnectionStopReason.unauthorized);
            return;
          }
          _attempt++;
        }
      }
    } finally {
      if (_runningGeneration == generation) _runningGeneration = null;
    }
  }

  void _onMessage(Object? raw, int generation) {
    if (_manualStop || generation != _generation) return;

    final WsMessage message;
    try {
      message = WsMessage.decode(raw);
    } on FormatException {
      return;
    }

    switch (message.type) {
      case WsTypes.pong:
        _pongTimer?.cancel();
        _pongTimer = null;
        return;
      case WsTypes.hello:
        final hello = PcHello.fromData(message.data);
        if (state is ConnectionConnected) {
          state = ConnectionConnected(hello: hello);
        }
        break;
      case WsTypes.bye:
        _stopWith(ConnectionStopReason.revoked);
        return;
    }

    if (!_messages.isClosed) _messages.add(message);
  }

  void _onClosed(int generation) {
    if (_manualStop || generation != _generation) return;

    final connection = _connection;
    if (connection == null) return;

    final code = connection.closeCode;
    _detach();

    if (code == 4001) {
      _stopWith(ConnectionStopReason.revoked);
      return;
    }
    if (code == 4003) {
      _stopWith(ConnectionStopReason.disabled);
      return;
    }

    _attempt++;
    unawaited(_run(generation));
  }

  void _startHeartbeat(int generation) {
    _heartbeatTimer?.cancel();
    _pongTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _config.heartbeatInterval,
      (_) => _sendPing(generation),
    );
  }

  void _sendPing(int generation) {
    if (_manualStop || generation != _generation || _connection == null) {
      return;
    }

    send(const WsMessage(type: WsTypes.ping));
    _pongTimer?.cancel();
    _pongTimer = Timer(_config.pongTimeout, () => _onPongTimeout(generation));
  }

  void _onPongTimeout(int generation) {
    _pongTimer = null;
    if (_manualStop || generation != _generation || _connection == null) {
      return;
    }

    _detach();
    _attempt++;
    unawaited(_run(generation));
  }

  void _stopWith(ConnectionStopReason reason) {
    _manualStop = true;
    _detach();
    state = ConnectionStopped(reason);
  }

  void _detach() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimer?.cancel();
    _pongTimer = null;

    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());

    final connection = _connection;
    _connection = null;
    if (connection != null) unawaited(_safeClose(connection));
  }

  Future<void> _safeClose(WsConnection connection) async {
    try {
      await connection.close();
    } catch (_) {
      // The socket may already be closed.
    }
  }

  bool _isUnauthorized(Object error) {
    if (error is WsConnectException) return error.statusCode == 401;
    final text = error.toString();
    return text.contains('401') || text.toLowerCase().contains('unauthorized');
  }

  ConnectionConfig get _config => ref.read(connectionConfigProvider);
}
