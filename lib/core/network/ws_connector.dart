import 'dart:async';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsConnectException implements Exception {
  const WsConnectException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'WsConnectException($statusCode): $message';
}

abstract interface class WsConnector {
  Future<WsConnection> connect(
    Uri uri, {
    Map<String, String> headers = const {},
  });
}

abstract interface class WsConnection {
  Stream<dynamic> get messages;

  Future<void> get ready;

  int? get closeCode;

  String? get closeReason;

  void send(String data);

  Future<void> close([int? code, String? reason]);
}

class IOWsConnector implements WsConnector {
  const IOWsConnector({this.connectTimeout = const Duration(seconds: 10)});

  final Duration connectTimeout;

  @override
  Future<WsConnection> connect(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: headers,
      connectTimeout: connectTimeout,
    );

    try {
      await channel.ready;
    } catch (error) {
      try {
        await channel.sink.close();
      } catch (_) {
        // The handshake already failed; the socket is unusable.
      }
      throw _mapError(error);
    }

    return _IOWsConnection(channel);
  }

  WsConnectException _mapError(Object error) {
    final message = error.toString();
    return WsConnectException(message, statusCode: _statusCode(message));
  }

  int? _statusCode(String message) {
    if (message.contains('401')) return 401;
    if (message.contains('403')) return 403;
    return null;
  }
}

class _IOWsConnection implements WsConnection {
  const _IOWsConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  Future<void> get ready => _channel.ready;

  @override
  int? get closeCode => _channel.closeCode;

  @override
  String? get closeReason => _channel.closeReason;

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close([int? code, String? reason]) =>
      _channel.sink.close(code, reason);
}
