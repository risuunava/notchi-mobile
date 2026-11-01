import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notchi_mobile/core/network/api_client.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/pairing/state/pairing_providers.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';
import 'package:notchi_mobile/models/pair_result.dart';
import 'package:notchi_mobile/models/pc_info.dart';

const testPcInfo = PcInfo(
  apiVersion: 1,
  appVersion: '1.1.0',
  pcId: 'pc-1',
  pcName: 'LAPTOP-TEST',
);

const testPairResult = PairResult(
  sessionToken: 'session-abc',
  pcId: 'pc-1',
  pcName: 'LAPTOP-TEST',
);

const testQr =
    'notchi://pair?host=192.168.1.10&port=8765&token=tok-1&pc=pc-1&name=LAPTOP-TEST&v=1';

class FakeApi implements NotchiApi {
  FakeApi({
    this.info = testPcInfo,
    this.result = testPairResult,
    this.infoError,
    this.pairError,
  });

  PcInfo info;
  PairResult result;
  Object? infoError;
  Object? pairError;
  Completer<PairResult>? pairCompleter;

  int infoCalls = 0;
  int pairCalls = 0;
  String? lastPairingToken;
  String? lastDeviceId;
  String? lastDeviceName;

  @override
  Future<PcInfo> fetchInfo({required String host, required int port}) async {
    infoCalls++;
    if (infoError != null) throw infoError!;
    return info;
  }

  @override
  Future<PairResult> pair({
    required String host,
    required int port,
    required String pairingToken,
    required String deviceId,
    required String deviceName,
  }) async {
    pairCalls++;
    lastPairingToken = pairingToken;
    lastDeviceId = deviceId;
    lastDeviceName = deviceName;

    final completer = pairCompleter;
    if (completer != null) return completer.future;
    if (pairError != null) throw pairError!;
    return result;
  }
}

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

ProviderContainer makeContainer({
  required NotchiApi api,
  required KeyValueStore store,
}) {
  return ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      keyValueStoreProvider.overrideWithValue(store),
    ],
  );
}
