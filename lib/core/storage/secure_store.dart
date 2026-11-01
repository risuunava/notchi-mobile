import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../json/json_utils.dart';
import '../../models/device_identity.dart';

abstract interface class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements KeyValueStore {
  const FlutterSecureKeyValueStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SavedSession {
  const SavedSession({
    required this.sessionToken,
    required this.pcId,
    required this.pcName,
    required this.host,
    required this.port,
    required this.apiVersion,
  });

  final String sessionToken;
  final String pcId;
  final String pcName;
  final String host;
  final int port;
  final int apiVersion;

  Map<String, dynamic> toJson() {
    return {
      'sessionToken': sessionToken,
      'pcId': pcId,
      'pcName': pcName,
      'host': host,
      'port': port,
      'apiVersion': apiVersion,
    };
  }

  factory SavedSession.fromJson(Map<String, dynamic> json) {
    return SavedSession(
      sessionToken: requiredJsonString(json, 'sessionToken'),
      pcId: requiredJsonString(json, 'pcId'),
      pcName: requiredJsonString(json, 'pcName'),
      host: requiredJsonString(json, 'host'),
      port: requiredJsonInt(json, 'port'),
      apiVersion: requiredJsonInt(json, 'apiVersion'),
    );
  }
}

class SessionStore {
  SessionStore(this._store, {Future<String> Function()? deviceNameResolver})
    : _deviceNameResolver = deviceNameResolver ?? resolveDeviceName;

  static const _sessionKey = 'notchi.session';
  static const _deviceIdKey = 'notchi.device_id';
  static const _deviceNameKey = 'notchi.device_name';

  final KeyValueStore _store;
  final Future<String> Function() _deviceNameResolver;

  Future<DeviceIdentity> ensureIdentity({String? preferredName}) async {
    var deviceId = await _store.read(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _store.write(_deviceIdKey, deviceId);
    }

    final preferred = preferredName?.trim();
    var deviceName = preferred == null || preferred.isEmpty
        ? await _store.read(_deviceNameKey)
        : preferred;

    if (deviceName == null || deviceName.trim().isEmpty) {
      deviceName = (await _deviceNameResolver()).trim();
    }
    if (deviceName.isEmpty) {
      deviceName = 'Android';
    }

    if (deviceName != await _store.read(_deviceNameKey)) {
      await _store.write(_deviceNameKey, deviceName);
    }

    return DeviceIdentity(deviceId: deviceId, deviceName: deviceName);
  }

  Future<SavedSession?> readSession() async {
    final raw = await _store.read(_sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      return SavedSession.fromJson(asJsonMap(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(SavedSession session) {
    return _store.write(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() => _store.delete(_sessionKey);

  Future<void> clearAll() async {
    await _store.delete(_sessionKey);
    await _store.delete(_deviceIdKey);
    await _store.delete(_deviceNameKey);
  }
}

Future<String> resolveDeviceName() async {
  if (!Platform.isAndroid) return 'Android';

  try {
    final info = await DeviceInfoPlugin().androidInfo;
    final label = [
      info.brand,
      info.model,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');
    if (label.isNotEmpty) return label;
  } catch (_) {
    // Fall back to a generic name when device information is unavailable.
  }

  return 'Android';
}
