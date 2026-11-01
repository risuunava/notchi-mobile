import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';

import '../helpers/fakes.dart';

void main() {
  group('SessionStore', () {
    late InMemoryKeyValueStore store;
    late SessionStore sessionStore;

    setUp(() {
      store = InMemoryKeyValueStore();
      sessionStore = SessionStore(
        store,
        deviceNameResolver: () async => 'Pixel Test',
      );
    });

    test('generates a stable device id and name', () async {
      final first = await sessionStore.ensureIdentity();
      final second = await sessionStore.ensureIdentity();

      expect(first.deviceId, isNotEmpty);
      expect(first.deviceId, second.deviceId);
      expect(first.deviceName, 'Pixel Test');
      expect(store.values, contains('notchi.device_id'));
    });

    test('reuses a preferred device name', () async {
      await sessionStore.ensureIdentity(preferredName: 'HP Faris');
      final identity = await sessionStore.ensureIdentity();

      expect(identity.deviceName, 'HP Faris');
    });

    test('saves and reads a session', () async {
      const session = SavedSession(
        sessionToken: 'secret-token',
        pcId: 'pc-1',
        pcName: 'LAPTOP-TEST',
        host: '192.168.1.10',
        port: 8765,
        apiVersion: 1,
      );

      await sessionStore.saveSession(session);
      final restored = await sessionStore.readSession();

      expect(restored?.sessionToken, 'secret-token');
      expect(restored?.pcId, 'pc-1');
      expect(restored?.pcName, 'LAPTOP-TEST');
      expect(restored?.host, '192.168.1.10');
      expect(restored?.port, 8765);
      expect(restored?.apiVersion, 1);
    });

    test('returns null for a missing or corrupted session', () async {
      expect(await sessionStore.readSession(), isNull);

      store.values['notchi.session'] = 'not-json';
      expect(await sessionStore.readSession(), isNull);

      store.values['notchi.session'] = jsonEncode({'sessionToken': 'x'});
      expect(await sessionStore.readSession(), isNull);
    });

    test('clears the session but keeps the device id', () async {
      final identity = await sessionStore.ensureIdentity();
      await sessionStore.saveSession(
        const SavedSession(
          sessionToken: 'token',
          pcId: 'pc-1',
          pcName: 'PC',
          host: '10.0.0.2',
          port: 8765,
          apiVersion: 1,
        ),
      );

      await sessionStore.clearSession();

      expect(await sessionStore.readSession(), isNull);
      expect(store.values['notchi.device_id'], identity.deviceId);
    });
  });
}
