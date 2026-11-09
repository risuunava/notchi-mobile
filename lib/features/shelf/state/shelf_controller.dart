import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/api_error.dart';
import '../../../core/network/protocol.dart';
import '../../connection/state/connection_providers.dart';
import '../../pairing/state/pairing_providers.dart';
import '../../pairing/state/session_providers.dart';
import '../model/shelf_item.dart';

enum ShelfUploadStatus { idle, uploading, downloading, success, error }

class ShelfUploadState {
  const ShelfUploadState({
    this.status = ShelfUploadStatus.idle,
    this.progress = 0.0,
    this.lastResult,
    this.error,
    this.history = const [],
    this.incomingFileName,
  });

  final ShelfUploadStatus status;
  final double progress;
  final ShelfUploadResult? lastResult;
  final ApiError? error;
  final List<ShelfHistoryEntry> history;
  final String? incomingFileName;

  ShelfUploadState copyWith({
    ShelfUploadStatus? status,
    double? progress,
    ShelfUploadResult? lastResult,
    ApiError? error,
    List<ShelfHistoryEntry>? history,
    String? incomingFileName,
  }) {
    return ShelfUploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      lastResult: lastResult ?? this.lastResult,
      error: error,
      history: history ?? this.history,
      incomingFileName: incomingFileName,
    );
  }
}

class ShelfController extends Notifier<ShelfUploadState> {
  static const _historyKey = 'notchi.shelf_history';
  static const _maxHistory = 50;

  CancelToken? _cancelToken;
  CancelToken? _downloadCancelToken;
  StreamSubscription<WsMessage>? _wsSubscription;

  @override
  ShelfUploadState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
      _downloadCancelToken?.cancel();
      _wsSubscription?.cancel();
    });

    _wsSubscription = ref.watch(connectionMessagesProvider).listen(_onWsMessage);

    unawaited(_restoreHistory());
    return const ShelfUploadState();
  }

  void _onWsMessage(WsMessage message) {
    if (message.type == WsTypes.shelfFile) {
      final data = message.data;
      if (data != null) {
        final id = data['id'] as String? ?? '';
        final name = data['name'] as String? ?? 'file';
        final size = (data['size'] as num?)?.toInt();
        unawaited(_handleIncomingFile(id: id, name: name, size: size));
      }
    } else if (message.type == WsTypes.shelfText) {
      final data = message.data;
      if (data != null) {
        final id = data['id'] as String? ?? '';
        final text = data['text'] as String? ?? '';
        if (text.isNotEmpty) {
          unawaited(_handleIncomingText(id: id, text: text));
        }
      }
    }
  }

  Future<void> _handleIncomingFile({
    required String id,
    required String name,
    int? size,
  }) async {
    final session = ref.read(savedSessionProvider).asData?.value;
    if (session == null) return;

    _downloadCancelToken?.cancel();
    _downloadCancelToken = CancelToken();

    state = state.copyWith(
      status: ShelfUploadStatus.downloading,
      progress: 0.0,
      incomingFileName: name,
    );

    try {
      final saveDir = await _resolveDownloadDirectory();
      final destinationPath = await _getUniqueFilePath(saveDir, name);

      final client = ref.read(apiClientProvider);
      await client.downloadShelfFile(
        host: session.host,
        port: session.port,
        sessionToken: session.sessionToken,
        fileId: id,
        savePath: destinationPath,
        cancelToken: _downloadCancelToken,
        onProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(progress: received / total);
          }
        },
      );

      final downloadedFile = File(destinationPath);
      final finalSize = size ?? (await downloadedFile.length());

      final entry = ShelfHistoryEntry(
        id: id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        size: finalSize,
        isText: false,
        createdAt: DateTime.now(),
        filePath: destinationPath,
        isIncoming: true,
      );

      final history = [entry, ...state.history].take(_maxHistory).toList();
      state = state.copyWith(
        status: ShelfUploadStatus.success,
        progress: 1.0,
        lastResult: ShelfUploadResult(id: entry.id, name: name, size: finalSize),
        history: history,
        incomingFileName: null,
      );
      await _persistHistory(history);

      ref.read(connectionControllerProvider.notifier).send(
        WsMessage(
          type: WsTypes.shelfAck,
          id: id,
          data: {'success': true, 'name': name},
        ),
      );
    } on ApiError catch (e) {
      state = state.copyWith(
        status: ShelfUploadStatus.error,
        error: e,
        incomingFileName: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ShelfUploadStatus.error,
        error: ApiError(ApiErrorCode.unknown, detail: e.toString()),
        incomingFileName: null,
      );
    }
  }

  Future<void> _handleIncomingText({
    required String id,
    required String text,
  }) async {
    final entry = ShelfHistoryEntry(
      id: id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Catatan dari PC',
      isText: true,
      content: text,
      createdAt: DateTime.now(),
      isIncoming: true,
    );

    final history = [entry, ...state.history].take(_maxHistory).toList();
    state = state.copyWith(history: history);
    await _persistHistory(history);

    ref.read(connectionControllerProvider.notifier).send(
      WsMessage(
        type: WsTypes.shelfAck,
        id: id,
        data: {'success': true, 'name': 'Catatan dari PC'},
      ),
    );
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        return publicDownload;
      }
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final notchiDir = Directory('${docDir.path}/Notchi');
      if (!await notchiDir.exists()) {
        await notchiDir.create(recursive: true);
      }
      return notchiDir;
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<String> _getUniqueFilePath(Directory dir, String fileName) async {
    final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    var target = File('${dir.path}/$sanitized');
    if (!await target.exists()) return target.path;

    final dotIndex = sanitized.lastIndexOf('.');
    final base = dotIndex != -1 ? sanitized.substring(0, dotIndex) : sanitized;
    final ext = dotIndex != -1 ? sanitized.substring(dotIndex) : '';

    var counter = 1;
    while (await target.exists()) {
      target = File('${dir.path}/$base ($counter)$ext');
      counter++;
    }
    return target.path;
  }

  Future<void> _restoreHistory() async {
    try {
      final raw = await ref.read(keyValueStoreProvider).read(_historyKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final loaded = decoded
          .whereType<Map>()
          .map(
            (item) => ShelfHistoryEntry.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();

      final merged = <ShelfHistoryEntry>[];
      final seen = <String>{};
      for (final entry in [...state.history, ...loaded]) {
        if (seen.add(entry.id)) merged.add(entry);
      }
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(history: merged.take(_maxHistory).toList());
    } catch (_) {
      // History is a convenience; ignore unreadable values.
    }
  }

  Future<void> _persistHistory(List<ShelfHistoryEntry> history) async {
    try {
      await ref
          .read(keyValueStoreProvider)
          .write(
            _historyKey,
            jsonEncode(history.map((entry) => entry.toJson()).toList()),
          );
    } catch (_) {
      // Keep the in-memory history when persistence fails.
    }
  }

  Future<void> _recordSuccess(
    ShelfUploadResult result, {
    required bool isText,
    String? filePath,
    String? content,
  }) async {
    final entry = ShelfHistoryEntry.fromUpload(
      result,
      isText: isText,
      filePath: filePath,
      content: content,
      isIncoming: false,
    );
    final history = [entry, ...state.history].take(_maxHistory).toList();

    state = state.copyWith(
      status: ShelfUploadStatus.success,
      progress: 1.0,
      lastResult: result,
      history: history,
    );

    await _persistHistory(history);
  }

  Future<void> clearHistory() async {
    state = state.copyWith(history: const []);
    try {
      await ref.read(keyValueStoreProvider).delete(_historyKey);
    } catch (_) {
      // Nothing else to do if the stored history cannot be removed.
    }
  }

  Future<void> deleteHistoryEntry(String id) async {
    final history = state.history.where((entry) => entry.id != id).toList();
    state = state.copyWith(history: history);
    await _persistHistory(history);
  }

  Future<void> sendText(String text) async {
    final session = ref.read(savedSessionProvider).asData?.value;
    if (session == null) {
      state = state.copyWith(
        status: ShelfUploadStatus.error,
        error: const ApiError(ApiErrorCode.invalidToken),
      );
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(status: ShelfUploadStatus.uploading, progress: 0.0);

    try {
      final client = ref.read(apiClientProvider);
      final result = await client.uploadToShelf(
        host: session.host,
        port: session.port,
        sessionToken: session.sessionToken,
        text: text,
        cancelToken: _cancelToken,
      );

      await _recordSuccess(result, isText: true, content: text);
    } on ApiError catch (e) {
      state = state.copyWith(status: ShelfUploadStatus.error, error: e);
    } catch (e) {
      state = state.copyWith(
        status: ShelfUploadStatus.error,
        error: ApiError(ApiErrorCode.unknown, detail: e.toString()),
      );
    }
  }

  Future<void> sendFile({
    required String filePath,
    String? fileName,
    List<int>? fileBytes,
  }) async {
    final session = ref.read(savedSessionProvider).asData?.value;
    if (session == null) {
      state = state.copyWith(
        status: ShelfUploadStatus.error,
        error: const ApiError(ApiErrorCode.invalidToken),
      );
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(status: ShelfUploadStatus.uploading, progress: 0.0);

    try {
      final client = ref.read(apiClientProvider);
      final result = await client.uploadToShelf(
        host: session.host,
        port: session.port,
        sessionToken: session.sessionToken,
        filePath: filePath,
        fileName: fileName,
        fileBytes: fileBytes,
        cancelToken: _cancelToken,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      await _recordSuccess(
        result,
        isText: false,
        filePath: filePath.isNotEmpty ? filePath : null,
      );
    } on ApiError catch (e) {
      state = state.copyWith(status: ShelfUploadStatus.error, error: e);
    } catch (e) {
      state = state.copyWith(
        status: ShelfUploadStatus.error,
        error: ApiError(ApiErrorCode.unknown, detail: e.toString()),
      );
    }
  }

  void cancel() {
    _cancelToken?.cancel();
    _downloadCancelToken?.cancel();
    state = ShelfUploadState(history: state.history);
  }

  void reset() {
    state = ShelfUploadState(history: state.history);
  }
}

final shelfControllerProvider =
    NotifierProvider<ShelfController, ShelfUploadState>(ShelfController.new);
