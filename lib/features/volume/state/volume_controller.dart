import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/protocol.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../model/volume_state.dart';

class VolumeController extends Notifier<VolumeState> {
  StreamSubscription<WsMessage>? _subscription;

  @override
  VolumeState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _subscription = ref.watch(connectionMessagesProvider).listen(_onMessage);

    ref.listen<ConnectionStatus>(connectionControllerProvider, (
      previous,
      next,
    ) {
      if (next is ConnectionConnected) {
        _requestState();
      }
    });

    // The server only pushes volume.state on connect/commands, so ask for the
    // current value once in case we missed the initial push.
    unawaited(Future<void>.microtask(_requestState));

    return VolumeState.empty;
  }

  void _onMessage(WsMessage message) {
    if (message.type == WsTypes.volumeState) {
      state = VolumeState.fromJson(message.data);
    }
  }

  void setLevel(double level) {
    final clamped = level.clamp(0.0, 1.0).toDouble();
    final previous = state;

    state = state.copyWith(level: clamped);
    if (previous.muted) {
      state = state.copyWith(muted: false);
    }

    final ok = _send(WsMessage(type: WsTypes.volumeSet, data: {'level': clamped}));
    if (!ok) {
      state = previous;
      return;
    }

    // Moving the volume slider also unmutes, matching the desktop behavior.
    if (previous.muted) {
      final ok2 = _send(
        WsMessage(type: WsTypes.volumeMute, data: {'muted': false}),
      );
      if (!ok2) {
        state = previous;
        return;
      }
    }
  }

  void setMuted(bool muted) {
    final previous = state.muted;
    state = state.copyWith(muted: muted);
    final ok = _send(WsMessage(type: WsTypes.volumeMute, data: {'muted': muted}));
    if (!ok) {
      state = state.copyWith(muted: previous);
    }
  }

  void toggleMute() {
    final next = !state.muted;
    final previous = state.muted;
    state = state.copyWith(muted: next);
    final ok = _send(const WsMessage(type: WsTypes.volumeToggle));
    if (!ok) {
      state = state.copyWith(muted: previous);
    }
  }

  void _requestState() {
    final status = ref.read(connectionControllerProvider);
    if (status is ConnectionConnected) {
      _send(const WsMessage(type: WsTypes.volumeGet));
    }
  }

  bool _send(WsMessage message) {
    final notifier = ref.read(connectionControllerProvider.notifier);
    final ok = notifier.send(message);
    if (!ok) {
      notifier.reconnect();
      debugPrint('[VolumeController] send failed, reconnection triggered');
    }
    return ok;
  }
}

final volumeControllerProvider =
    NotifierProvider<VolumeController, VolumeState>(VolumeController.new);
