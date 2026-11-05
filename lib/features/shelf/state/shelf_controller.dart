import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_error.dart';
import '../../pairing/state/pairing_providers.dart';
import '../../pairing/state/session_providers.dart';
import '../model/shelf_item.dart';

enum ShelfUploadStatus { idle, uploading, success, error }

class ShelfUploadState {
  const ShelfUploadState({
    this.status = ShelfUploadStatus.idle,
    this.progress = 0.0,
    this.lastResult,
    this.error,
    this.history = const [],
  });

  final ShelfUploadStatus status;
  final double progress;
  final ShelfUploadResult? lastResult;
  final ApiError? error;
  final List<ShelfHistoryEntry> history;

  ShelfUploadState copyWith({
    ShelfUploadStatus? status,
    double? progress,
    ShelfUploadResult? lastResult,
    ApiError? error,
    List<ShelfHistoryEntry>? history,
  }) {
    return ShelfUploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      lastResult: lastResult ?? this.lastResult,
      error: error,
      history: history ?? this.history,
    );
  }
}

class ShelfController extends Notifier<ShelfUploadState> {
  static const _historyKey = 'notchi.shelf_history';
  static const _maxHistory = 50;

  CancelToken? _cancelToken;

  @override
  ShelfUploadState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    unawaited(_restoreHistory());
    return const ShelfUploadState();
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
    state = ShelfUploadState(history: state.history);
  }

  void reset() {
    state = ShelfUploadState(history: state.history);
  }
}

final shelfControllerProvider =
    NotifierProvider<ShelfController, ShelfUploadState>(ShelfController.new);
