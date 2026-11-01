import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/protocol.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../../pairing/state/pairing_providers.dart';
import '../../pairing/state/session_providers.dart';
import '../model/media_state.dart';

class MediaController extends Notifier<MediaState?> {
  StreamSubscription<WsMessage>? _subscription;
  int? _lastArtVersion;
  Uint8List? _cachedArtBytes;

  Uint8List? get cachedArt => _cachedArtBytes;

  @override
  MediaState? build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Listen to incoming WebSocket messages
    _subscription = ref.watch(connectionMessagesProvider).listen(_onWsMessage);

    // Reset when disconnected or idle
    ref.listen<ConnectionStatus>(connectionControllerProvider, (previous, next) {
      if (next is! ConnectionConnected) {
        state = null;
        _lastArtVersion = null;
        _cachedArtBytes = null;
      }
    });

    return null;
  }

  void _onWsMessage(WsMessage message) {
    if (message.type == WsTypes.mediaState) {
      final newState = MediaState.fromJson(message.data);
      state = newState;
      _checkArtUpdate(newState.artVersion);
    }
  }

  Future<void> _checkArtUpdate(int artVersion) async {
    if (artVersion <= 0) {
      _cachedArtBytes = null;
      _lastArtVersion = 0;
      return;
    }

    if (_lastArtVersion == artVersion) return;

    final session = ref.read(savedSessionProvider).asData?.value;
    if (session == null) return;

    try {
      final art = await ref
          .read(apiClientProvider)
          .fetchMediaArt(
            host: session.host,
            port: session.port,
            sessionToken: session.sessionToken,
            artVersion: artVersion,
          );
      _cachedArtBytes = art;
      _lastArtVersion = artVersion;
      // Trigger update with same state to refresh listeners that consume art
      if (state != null) {
        state = state!.copyWith();
      }
    } catch (_) {
      // Best-effort image fetch
    }
  }

  void play() {
    _send(const WsMessage(type: WsTypes.mediaPlay));
  }

  void pause() {
    _send(const WsMessage(type: WsTypes.mediaPause));
  }

  void toggle() {
    _send(const WsMessage(type: WsTypes.mediaToggle));
  }

  void next() {
    _send(const WsMessage(type: WsTypes.mediaNext));
  }

  void previous() {
    _send(const WsMessage(type: WsTypes.mediaPrev));
  }

  void seek(double positionSeconds) {
    _send(
      WsMessage(
        type: WsTypes.mediaSeek,
        data: {'positionSeconds': positionSeconds},
      ),
    );
  }

  void _send(WsMessage message) {
    ref.read(connectionControllerProvider.notifier).send(message);
  }
}

final mediaControllerProvider =
    NotifierProvider<MediaController, MediaState?>(MediaController.new);

final mediaArtProvider = Provider<Uint8List?>((ref) {
  // Watch mediaControllerProvider so that art updates when media changes
  ref.watch(mediaControllerProvider);
  return ref.watch(mediaControllerProvider.notifier).cachedArt;
});
