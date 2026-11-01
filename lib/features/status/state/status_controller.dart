import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/protocol.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../model/system_status.dart';

class SystemStatusController extends Notifier<SystemStatus?> {
  StreamSubscription<WsMessage>? _messageSub;
  int _activeSubscribers = 0;

  @override
  SystemStatus? build() {
    ref.onDispose(() {
      _messageSub?.cancel();
    });

    _messageSub = ref.watch(connectionMessagesProvider).listen(_onWsMessage);

    ref.listen<ConnectionStatus>(connectionControllerProvider, (previous, next) {
      if (next is! ConnectionConnected) {
        state = null;
      } else if (_activeSubscribers > 0) {
        _send(
          const WsMessage(
            type: WsTypes.statusSubscribe,
            data: {'intervalMs': 2000},
          ),
        );
      }
    });

    return null;
  }

  void subscribe() {
    _activeSubscribers++;
    if (_activeSubscribers == 1) {
      _send(
        const WsMessage(
          type: WsTypes.statusSubscribe,
          data: {'intervalMs': 2000},
        ),
      );
    }
  }

  void unsubscribe() {
    if (_activeSubscribers > 0) {
      _activeSubscribers--;
      if (_activeSubscribers == 0) {
        _send(const WsMessage(type: WsTypes.statusUnsubscribe));
      }
    }
  }

  void _onWsMessage(WsMessage message) {
    if (message.type == WsTypes.statusUpdate) {
      if (message.data != null) {
        state = SystemStatus.fromJson(message.data!);
      }
    }
  }

  void _send(WsMessage message) {
    ref.read(connectionControllerProvider.notifier).send(message);
  }
}

final systemStatusControllerProvider =
    NotifierProvider<SystemStatusController, SystemStatus?>(
      SystemStatusController.new,
    );
