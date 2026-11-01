import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/network/protocol.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
import 'package:notchi_mobile/features/media/state/media_controller.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';

import '../../helpers/fakes.dart';

void main() {
  const session = SavedSession(
    sessionToken: 'test-token',
    pcId: 'pc-1',
    pcName: 'LAPTOP-TEST',
    host: '192.168.1.10',
    port: 8765,
    apiVersion: 1,
  );

  test('updates state on media.state message and sends control actions', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final api = FakeApi(artBytes: Uint8List.fromList([1, 2, 3, 4]));
      final store = InMemoryKeyValueStore();
      final container = makeContainer(
        api: api,
        store: store,
        wsConnector: connector,
      );

      // Save session in store
      SessionStore(store).saveSession(session);
      container.read(savedSessionProvider);

      // Connect
      // Read provider to initialize it
      container.read(mediaControllerProvider);

      container.read(connectionControllerProvider.notifier).connect(session);
      async.flushMicrotasks();

      final conn = connector.connection!;
      final mediaController = container.read(mediaControllerProvider.notifier);

      expect(container.read(mediaControllerProvider), isNull);

      // Emit media.state via websocket
      conn.incoming.add(
        jsonEncode({
          'type': WsTypes.mediaState,
          'data': {
            'available': true,
            'title': 'Bohemian Rhapsody',
            'artist': 'Queen',
            'album': 'A Night at the Opera',
            'sourceApp': 'Spotify',
            'playing': true,
            'positionSeconds': 45.0,
            'durationSeconds': 354.0,
            'canSeek': true,
            'artVersion': 1,
          },
        }),
      );
      async.flushMicrotasks();

      final state = container.read(mediaControllerProvider);
      expect(state, isNotNull);
      expect(state!.title, 'Bohemian Rhapsody');
      expect(state.artist, 'Queen');
      expect(state.playing, isTrue);
      expect(state.artVersion, 1);

      // Check art fetch
      expect(api.artCalls, 1);
      expect(api.lastArtVersion, 1);
      expect(container.read(mediaArtProvider), isNotNull);

      // Test control commands
      mediaController.play();
      expect(conn.sentMessages.last, jsonEncode({'type': WsTypes.mediaPlay}));

      mediaController.pause();
      expect(conn.sentMessages.last, jsonEncode({'type': WsTypes.mediaPause}));

      mediaController.toggle();
      expect(conn.sentMessages.last, jsonEncode({'type': WsTypes.mediaToggle}));

      mediaController.next();
      expect(conn.sentMessages.last, jsonEncode({'type': WsTypes.mediaNext}));

      mediaController.previous();
      expect(conn.sentMessages.last, jsonEncode({'type': WsTypes.mediaPrev}));

      mediaController.seek(120.0);
      expect(
        conn.sentMessages.last,
        jsonEncode({
          'type': WsTypes.mediaSeek,
          'data': {'positionSeconds': 120.0},
        }),
      );

      container.dispose();
    });
  });

  test('clears media state when connection is stopped/disconnected', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      // Read provider to initialize it
      container.read(mediaControllerProvider);

      container.read(connectionControllerProvider.notifier).connect(session);
      async.flushMicrotasks();

      final conn = connector.connection!;
      conn.incoming.add(
        jsonEncode({
          'type': WsTypes.mediaState,
          'data': {
            'available': true,
            'title': 'Song A',
            'artist': 'Artist B',
            'playing': true,
          },
        }),
      );
      async.flushMicrotasks();

      expect(container.read(mediaControllerProvider), isNotNull);

      // Disconnect
      container.read(connectionControllerProvider.notifier).disconnect();
      async.flushMicrotasks();

      expect(container.read(mediaControllerProvider), isNull);
      expect(container.read(mediaArtProvider), isNull);

      container.dispose();
    });
  });
}
