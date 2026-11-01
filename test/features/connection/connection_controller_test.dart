import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/network/ws_connector.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
import 'package:notchi_mobile/features/connection/state/connection_status.dart';

import '../../helpers/fakes.dart';

void main() {
  const session = SavedSession(
    sessionToken: 'token-abc',
    pcId: 'pc-1',
    pcName: 'LAPTOP-TEST',
    host: '192.168.1.50',
    port: 8765,
    apiVersion: 1,
  );

  test('connects successfully and sets Connected on hello', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);

      expect(
        container.read(connectionControllerProvider),
        isA<ConnectionConnecting>(),
      );

      async.flushMicrotasks();

      expect(connector.connectCalls.length, 1);
      expect(
        connector.connectCalls.first,
        Uri.parse('ws://192.168.1.50:8765/ws'),
      );
      expect(
        connector.headersCalls.first,
        {'Authorization': 'Bearer token-abc'},
      );
      expect(
        container.read(connectionControllerProvider),
        isA<ConnectionConnected>(),
      );

      // Simulate hello message
      final conn = connector.connection!;
      conn.incoming.add(
        '{"type":"hello","data":{"apiVersion":1,"pcName":"MyPC","mediaAvailable":true}}',
      );
      async.flushMicrotasks();

      final state =
          container.read(connectionControllerProvider) as ConnectionConnected;
      expect(state.hello?.pcName, 'MyPC');
      expect(state.hello?.mediaAvailable, isTrue);

      container.dispose();
    });
  });

  test('unexpected disconnect triggers Reconnecting with backoff sequence', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);
      async.flushMicrotasks();

      expect(
        container.read(connectionControllerProvider),
        isA<ConnectionConnected>(),
      );

      // Simulate disconnect from remote side
      connector.connection!.simulateRemoteClose();
      async.flushMicrotasks();

      // Attempt 1 backoff: 1s
      final state1 = container.read(connectionControllerProvider);
      expect(state1, isA<ConnectionReconnecting>());
      expect((state1 as ConnectionReconnecting).attempt, 1);
      expect(state1.delay, const Duration(seconds: 1));

      // Advance by 1s for reconnection attempt to fire
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(connector.connectCalls.length, 2);
      expect(
        container.read(connectionControllerProvider),
        isA<ConnectionConnected>(),
      );

      // Simulate failure again on connection 2
      connector.connection!.simulateRemoteClose();
      async.flushMicrotasks();

      // Attempt 1 backoff again after being connected: 1s
      final state2 = container.read(connectionControllerProvider);
      expect(state2, isA<ConnectionReconnecting>());
      expect((state2 as ConnectionReconnecting).attempt, 1);
      expect(state2.delay, const Duration(seconds: 1));

      container.dispose();
    });
  });

  test('pong timeout triggers reconnection', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);
      async.flushMicrotasks();

      final conn = connector.connection!;

      // Elapse 20 seconds to trigger ping
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();

      expect(conn.sentMessages.length, 1);
      expect(conn.sentMessages.first, contains('ping'));

      // Elapse 10 seconds without pong response
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      expect(
        container.read(connectionControllerProvider),
        isA<ConnectionReconnecting>(),
      );

      container.dispose();
    });
  });

  test('close 4001 stops with Unauthorized/revoked', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);
      async.flushMicrotasks();

      connector.connection!.simulateRemoteClose(4001, 'revoked');
      async.flushMicrotasks();

      final state = container.read(connectionControllerProvider);
      expect(state, isA<ConnectionStopped>());
      expect((state as ConnectionStopped).reason, ConnectionStopReason.revoked);

      container.dispose();
    });
  });

  test('close 4003 stops with Disabled', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);
      async.flushMicrotasks();

      connector.connection!.simulateRemoteClose(4003, 'disabled');
      async.flushMicrotasks();

      final state = container.read(connectionControllerProvider);
      expect(state, isA<ConnectionStopped>());
      expect((state as ConnectionStopped).reason, ConnectionStopReason.disabled);

      container.dispose();
    });
  });

  test('handshake 401 stops with Unauthorized', () {
    fakeAsync((async) {
      final connector = FakeWsConnector(
        connectHandler: (uri, headers) async {
          throw const WsConnectException('Unauthorized', statusCode: 401);
        },
      );
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);
      async.flushMicrotasks();

      final state = container.read(connectionControllerProvider);
      expect(state, isA<ConnectionStopped>());
      expect(
        (state as ConnectionStopped).reason,
        ConnectionStopReason.unauthorized,
      );

      container.dispose();
    });
  });

  test('corrupt or unknown JSON does not crash or close connection', () {
    fakeAsync((async) {
      final connector = FakeWsConnector();
      final container = makeContainer(
        api: FakeApi(),
        store: InMemoryKeyValueStore(),
        wsConnector: connector,
      );

      final controller = container.read(connectionControllerProvider.notifier);
      controller.connect(session);
      async.flushMicrotasks();

      final conn = connector.connection!;
      // Send broken / unexpected frames
      conn.incoming.add('{bad-json}');
      conn.incoming.add('{"unknown_field": 123}');
      conn.incoming.add('{"type":"unknown.event","data":{}}');
      async.flushMicrotasks();

      expect(
        container.read(connectionControllerProvider),
        isA<ConnectionConnected>(),
      );
      expect(conn.isClosed, isFalse);

      container.dispose();
    });
  });
}
