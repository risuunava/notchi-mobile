import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/protocol.dart';
import '../../../core/network/ws_connector.dart';
import 'connection_config.dart';
import 'connection_controller.dart';
import 'connection_status.dart';

final wsConnectorProvider = Provider<WsConnector>((ref) {
  return const IOWsConnector();
});

final connectionConfigProvider = Provider<ConnectionConfig>((ref) {
  return const ConnectionConfig();
});

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionStatus>(
      ConnectionController.new,
    );

final connectionMessagesProvider = Provider<Stream<WsMessage>>((ref) {
  return ref.watch(connectionControllerProvider.notifier).messages;
});
