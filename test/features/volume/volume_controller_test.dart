import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/network/protocol.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
import 'package:notchi_mobile/features/volume/state/volume_controller.dart';

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

  test('updates state on volume.state and sends set/mute/toggle commands', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      container.read(volumeControllerProvider);

      container.read(connectionControllerProvider.notifier).connect(session);
      async.flushMicrotasks();

      final conn = connector.connection!;
      final controller = container.read(volumeControllerProvider.notifier);

      conn.incoming.add(
        jsonEncode({
          'type': WsTypes.volumeState,
          'data': {'level': 0.41, 'muted': true},
        }),
      );
      async.flushMicrotasks();

      expect(container.read(volumeControllerProvider).level, closeTo(0.41, 1e-9));
      expect(container.read(volumeControllerProvider).muted, isTrue);

      controller.setLevel(0.75);
      expect(
        conn.sentMessages.where((m) => m.contains('volume.set')).last,
        jsonEncode({
          'type': WsTypes.volumeSet,
          'data': {'level': 0.75},
        }),
      );
      expect(
        conn.sentMessages.last,
        jsonEncode({
          'type': WsTypes.volumeMute,
          'data': {'muted': false},
        }),
      );
      expect(container.read(volumeControllerProvider).level, closeTo(0.75, 1e-9));
      expect(container.read(volumeControllerProvider).muted, isFalse);

      controller.setMuted(true);
      expect(
        conn.sentMessages.last,
        jsonEncode({
          'type': WsTypes.volumeMute,
          'data': {'muted': true},
        }),
      );
      expect(container.read(volumeControllerProvider).muted, isTrue);

      controller.toggleMute();
      expect(
        conn.sentMessages.last,
        jsonEncode({'type': WsTypes.volumeToggle}),
      );
      expect(container.read(volumeControllerProvider).muted, isFalse);

      container.dispose();
    });
  });

  test('reverts local state when there is no active connection', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      container.read(volumeControllerProvider);
      async.flushMicrotasks();

      final controller = container.read(volumeControllerProvider.notifier);

      controller.setLevel(0.9);
      expect(container.read(volumeControllerProvider).level, closeTo(0.5, 1e-9));

      controller.toggleMute();
      expect(container.read(volumeControllerProvider).muted, isFalse);

      expect(connector.connectCalls, isEmpty);

      container.dispose();
    });
  });
}
