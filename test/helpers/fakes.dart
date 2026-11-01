import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notchi_mobile/core/network/api_client.dart';
import 'package:notchi_mobile/core/network/ws_connector.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
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
    this.deleteError,
    this.artError,
    this.artBytes,
  });

  PcInfo info;
  PairResult result;
  Object? infoError;
  Object? pairError;
  Object? deleteError;
  Object? artError;
  Uint8List? artBytes;
  Completer<PairResult>? pairCompleter;

  int infoCalls = 0;
  int pairCalls = 0;
  int deleteCalls = 0;
  int artCalls = 0;
  int? lastArtVersion;
  String? lastPairingToken;
  String? lastDeviceId;
  String? lastDeviceName;
  String? lastSessionToken;

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

  @override
  Future<void> deleteDevice({
    required String host,
    required int port,
    required String sessionToken,
  }) async {
    deleteCalls++;
    lastSessionToken = sessionToken;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<Uint8List?> fetchMediaArt({
    required String host,
    required int port,
    required String sessionToken,
    int? artVersion,
  }) async {
    artCalls++;
    lastArtVersion = artVersion;
    if (artError != null) throw artError!;
    return artBytes;
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
  WsConnector? wsConnector,
}) {
  return ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      keyValueStoreProvider.overrideWithValue(store),
      if (wsConnector != null)
        wsConnectorProvider.overrideWithValue(wsConnector),
    ],
  );
}

class FakeWsConnector implements WsConnector {
  FakeWsConnector({this.connectHandler, this.connection});

  final Future<WsConnection> Function(Uri uri, Map<String, String> headers)?
  connectHandler;
  FakeWsConnection? connection;
  final List<Uri> connectCalls = [];
  final List<Map<String, String>> headersCalls = [];

  @override
  Future<WsConnection> connect(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    connectCalls.add(uri);
    headersCalls.add(headers);
    if (connectHandler != null) {
      return connectHandler!(uri, headers);
    }
    final existing = connection;
    if (existing != null && !existing.isClosed) {
      return existing;
    }
    final conn = FakeWsConnection();
    connection = conn;
    return conn;
  }
}

class FakeWsConnection implements WsConnection {
  FakeWsConnection({Completer<void>? readyCompleter})
    : _readyCompleter = readyCompleter ?? (Completer<void>()..complete());

  final StreamController<dynamic> incoming = StreamController<dynamic>.broadcast();
  final List<String> sentMessages = [];
  final Completer<void> _readyCompleter;

  int? _closeCode;
  String? _closeReason;
  bool isClosed = false;

  @override
  Stream<dynamic> get messages => incoming.stream;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  void send(String data) {
    sentMessages.add(data);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    _closeCode = code;
    _closeReason = reason;
    isClosed = true;
    if (!incoming.isClosed) {
      await incoming.close();
    }
  }

  void simulateRemoteClose([int? code, String? reason]) {
    _closeCode = code;
    _closeReason = reason;
    isClosed = true;
    if (!incoming.isClosed) {
      incoming.close();
    }
  }
}
