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
  });

  final ShelfUploadStatus status;
  final double progress;
  final ShelfUploadResult? lastResult;
  final ApiError? error;

  ShelfUploadState copyWith({
    ShelfUploadStatus? status,
    double? progress,
    ShelfUploadResult? lastResult,
    ApiError? error,
  }) {
    return ShelfUploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

class ShelfController extends Notifier<ShelfUploadState> {
  CancelToken? _cancelToken;

  @override
  ShelfUploadState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    return const ShelfUploadState();
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

      state = state.copyWith(
        status: ShelfUploadStatus.success,
        progress: 1.0,
        lastResult: result,
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

      state = state.copyWith(
        status: ShelfUploadStatus.success,
        progress: 1.0,
        lastResult: result,
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
    state = const ShelfUploadState();
  }

  void reset() {
    state = const ShelfUploadState();
  }
}

final shelfControllerProvider =
    NotifierProvider<ShelfController, ShelfUploadState>(ShelfController.new);
