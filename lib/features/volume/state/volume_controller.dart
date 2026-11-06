import 'dart:async';

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
    state = state.copyWith(level: clamped);

    _send(WsMessage(type: WsTypes.volumeSet, data: {'level': clamped}));

    // Moving the volume slider also unmutes, matching the desktop behavior.
    if (state.muted) {
      state = state.copyWith(muted: false);
      _send(WsMessage(type: WsTypes.volumeMute, data: {'muted': false}));
    }
  }

  void setMuted(bool muted) {
    state = state.copyWith(muted: muted);
    _send(WsMessage(type: WsTypes.volumeMute, data: {'muted': muted}));
  }

  void toggleMute() {
    final next = !state.muted;
    state = state.copyWith(muted: next);
    _send(const WsMessage(type: WsTypes.volumeToggle));
  }

  void _requestState() {
    final status = ref.read(connectionControllerProvider);
    if (status is ConnectionConnected) {
      _send(const WsMessage(type: WsTypes.volumeGet));
    }
  }

  void _send(WsMessage message) {
    ref.read(connectionControllerProvider.notifier).send(message);
  }
}

final volumeControllerProvider =
    NotifierProvider<VolumeController, VolumeState>(VolumeController.new);
