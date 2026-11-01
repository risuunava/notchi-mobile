import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/errors/api_error.dart';
import 'package:notchi_mobile/features/pairing/state/pairing_providers.dart';
import 'package:notchi_mobile/features/pairing/state/pairing_state.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';
import 'package:notchi_mobile/models/pair_result.dart';

import '../../helpers/fakes.dart';

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 500; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Condition was not met in time.');
}

void expectFailure(ProviderContainer container, ApiErrorCode code) {
  final state = container.read(pairingControllerProvider);
  expect(
    state,
    isA<PairingFailure>().having((failure) => failure.error.code, 'code', code),
  );
}

void main() {
  test('pairs with a valid QR and saves the session', () async {
    final api = FakeApi();
    final store = InMemoryKeyValueStore();
    final container = makeContainer(api: api, store: store);
    addTearDown(container.dispose);

    await container.read(pairingControllerProvider.notifier).pairWithQr(testQr);

    expect(container.read(pairingControllerProvider), isA<PairingSuccess>());
    expect(api.infoCalls, 1);
    expect(api.pairCalls, 1);
    expect(api.lastPairingToken, 'tok-1');
    expect(api.lastDeviceId, isNotEmpty);

    final session = await container.read(sessionStoreProvider).readSession();
    expect(session?.sessionToken, 'session-abc');
    expect(session?.host, '192.168.1.10');
    expect(session?.port, 8765);
    expect(session?.apiVersion, 1);
  });

  test('reports waiting approval while the PC prompt is pending', () async {
    final completer = Completer<PairResult>();
    final api = FakeApi()..pairCompleter = completer;
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    final future = container
        .read(pairingControllerProvider.notifier)
        .pairWithQr(testQr);

    await _waitUntil(() => api.pairCalls == 1);

    expect(
      container.read(pairingControllerProvider),
      isA<PairingConnecting>().having(
        (state) => state.stage,
        'stage',
        PairingStage.waitingApproval,
      ),
    );

    completer.complete(testPairResult);
    await future;

    expect(container.read(pairingControllerProvider), isA<PairingSuccess>());
  });

  test('maps a denied pairing to a failure', () async {
    final api = FakeApi(pairError: const ApiError(ApiErrorCode.pairingDenied));
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    await container.read(pairingControllerProvider.notifier).pairWithQr(testQr);

    expectFailure(container, ApiErrorCode.pairingDenied);
    expect(await container.read(sessionStoreProvider).readSession(), isNull);
  });

  test('maps an expired pairing token to a failure', () async {
    final api = FakeApi(
      pairError: const ApiError(ApiErrorCode.pairingTokenExpired),
    );
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    await container.read(pairingControllerProvider.notifier).pairWithQr(testQr);

    expectFailure(container, ApiErrorCode.pairingTokenExpired);
  });

  test('rejects an unrecognized QR without calling the server', () async {
    final api = FakeApi();
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    await container
        .read(pairingControllerProvider.notifier)
        .pairWithQr('https://example.com');

    expectFailure(container, ApiErrorCode.invalidQr);
    expect(api.infoCalls, 0);
    expect(api.pairCalls, 0);
  });

  test('rejects a QR that belongs to another PC', () async {
    final api = FakeApi();
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    await container
        .read(pairingControllerProvider.notifier)
        .pairWithQr(
          'notchi://pair?host=192.168.1.10&port=8765&token=tok-1&pc=other&v=1',
        );

    expectFailure(container, ApiErrorCode.pcMismatch);
    expect(api.pairCalls, 0);
  });

  test('validates manual connection input', () async {
    final api = FakeApi();
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    final controller = container.read(pairingControllerProvider.notifier);

    await controller.pairManually(host: '', port: '8765', token: 'token');
    expectFailure(container, ApiErrorCode.invalidHost);

    await controller.pairManually(
      host: '192.168.1.10',
      port: '0',
      token: 'token',
    );
    expectFailure(container, ApiErrorCode.invalidPort);

    await controller.pairManually(
      host: '192.168.1.10',
      port: '8765',
      token: '  ',
    );
    expectFailure(container, ApiErrorCode.missingToken);

    expect(api.infoCalls, 0);
  });

  test('maps network errors to a failure', () async {
    final api = FakeApi(infoError: const ApiError(ApiErrorCode.network));
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    await container.read(pairingControllerProvider.notifier).pairWithQr(testQr);

    expectFailure(container, ApiErrorCode.network);
    expect(api.pairCalls, 0);
  });

  test('pairs manually and reuses the device id', () async {
    final api = FakeApi();
    final container = makeContainer(api: api, store: InMemoryKeyValueStore());
    addTearDown(container.dispose);

    final controller = container.read(pairingControllerProvider.notifier);

    await controller.pairWithQr(testQr);
    expect(container.read(pairingControllerProvider), isA<PairingSuccess>());
    final firstDeviceId = api.lastDeviceId;

    await controller.pairManually(
      host: '192.168.1.10',
      port: '8765',
      token: 'tok-2',
      deviceName: 'HP Test',
    );

    expect(container.read(pairingControllerProvider), isA<PairingSuccess>());
    expect(api.pairCalls, 2);
    expect(api.lastDeviceId, firstDeviceId);
    expect(api.lastDeviceName, 'HP Test');
    expect(api.lastPairingToken, 'tok-2');
  });
}
