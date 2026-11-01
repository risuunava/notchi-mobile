import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/network/protocol.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';
import 'package:notchi_mobile/features/shelf/model/shelf_item.dart';
import 'package:notchi_mobile/features/shelf/state/shelf_controller.dart';
import 'package:notchi_mobile/features/status/state/status_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SystemStatusController', () {
    test('subscribes and updates state on status.update', () async {
      final fakeConn = FakeWsConnection();
      final fakeConnector = FakeWsConnector(
        connectHandler: (_, _) async => fakeConn,
      );
      final store = InMemoryKeyValueStore();
      const session = SavedSession(
        sessionToken: 'token',
        pcId: 'pc-1',
        pcName: 'LAPTOP-TEST',
        host: '192.168.1.10',
        port: 8765,
        apiVersion: 1,
      );
      await SessionStore(store).saveSession(session);

      final container = makeContainer(
        api: FakeApi(),
        store: store,
        wsConnector: fakeConnector,
      );

      final ctrl = container.read(systemStatusControllerProvider.notifier);
      container.read(connectionControllerProvider.notifier).connect(session);
      await pumpEventQueue();

      fakeConn.incoming.add(
        const WsMessage(
          type: WsTypes.hello,
          data: {'apiVersion': 1, 'pcName': 'PC'},
        ).encode(),
      );
      await pumpEventQueue();

      ctrl.subscribe();

      // Simulate status update frame
      fakeConn.incoming.add(
        const WsMessage(
          type: WsTypes.statusUpdate,
          data: {
            'cpuPercent': 45.5,
            'ramPercent': 70.0,
            'diskPercent': 55.2,
            'battery': {'percent': 80, 'charging': true},
          },
        ).encode(),
      );

      await pumpEventQueue();

      final status = container.read(systemStatusControllerProvider);
      expect(status, isNotNull);
      expect(status!.cpuPercent, 45.5);
      expect(status.ramPercent, 70.0);
      expect(status.diskPercent, 55.2);
      expect(status.battery?.percent, 80);
      expect(status.battery?.charging, isTrue);

      ctrl.unsubscribe();
      container.dispose();
    });
  });

  group('ShelfController', () {
    test('sends text and updates upload state', () async {
      final api = FakeApi(
        shelfResult: const ShelfUploadResult(id: 'txt-1', name: 'note.txt'),
      );
      final store = InMemoryKeyValueStore();
      await SessionStore(store).saveSession(
        const SavedSession(
          sessionToken: 'token',
          pcId: 'pc-1',
          pcName: 'LAPTOP-TEST',
          host: '192.168.1.10',
          port: 8765,
          apiVersion: 1,
        ),
      );

      final container = makeContainer(api: api, store: store);
      await container.read(savedSessionProvider.future);

      final ctrl = container.read(shelfControllerProvider.notifier);
      await ctrl.sendText('Hello drop shelf');

      final state = container.read(shelfControllerProvider);
      expect(state.status, ShelfUploadStatus.success);
      expect(state.lastResult?.name, 'note.txt');
      expect(api.shelfCalls, 1);
      expect(api.lastShelfText, 'Hello drop shelf');

      container.dispose();
    });

    test('sends file and updates progress', () async {
      final api = FakeApi(
        shelfResult: const ShelfUploadResult(id: 'img-1', name: 'photo.jpg', size: 1024),
      );
      final store = InMemoryKeyValueStore();
      await SessionStore(store).saveSession(
        const SavedSession(
          sessionToken: 'token',
          pcId: 'pc-1',
          pcName: 'LAPTOP-TEST',
          host: '192.168.1.10',
          port: 8765,
          apiVersion: 1,
        ),
      );

      final container = makeContainer(api: api, store: store);
      await container.read(savedSessionProvider.future);

      final ctrl = container.read(shelfControllerProvider.notifier);
      await ctrl.sendFile(
        filePath: '/tmp/photo.jpg',
        fileName: 'photo.jpg',
      );

      final state = container.read(shelfControllerProvider);
      expect(state.status, ShelfUploadStatus.success);
      expect(state.lastResult?.name, 'photo.jpg');
      expect(api.shelfCalls, 1);
      expect(api.lastShelfFilePath, '/tmp/photo.jpg');

      container.dispose();
    });
  });
}
