import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../errors/api_error.dart';
import '../json/json_utils.dart';
import '../../features/shelf/model/shelf_item.dart';
import '../../features/status/model/system_status.dart';
import '../../models/pair_result.dart';
import '../../models/pc_info.dart';

abstract interface class NotchiApi {
  Future<PcInfo> fetchInfo({required String host, required int port});

  Future<PairResult> pair({
    required String host,
    required int port,
    required String pairingToken,
    required String deviceId,
    required String deviceName,
  });

  Future<void> deleteDevice({
    required String host,
    required int port,
    required String sessionToken,
  });

  Future<Uint8List?> fetchMediaArt({
    required String host,
    required int port,
    required String sessionToken,
    int? artVersion,
  });

  Future<ShelfUploadResult> uploadToShelf({
    required String host,
    required int port,
    required String sessionToken,
    String? filePath,
    String? fileName,
    List<int>? fileBytes,
    String? text,
    void Function(int count, int total)? onProgress,
    CancelToken? cancelToken,
  });

  Future<SystemStatus> fetchStatus({
    required String host,
    required int port,
    required String sessionToken,
  });
}

class ApiClient implements NotchiApi {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 120),
              receiveTimeout: const Duration(seconds: 120),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  @override
  Future<PcInfo> fetchInfo({required String host, required int port}) async {
    try {
      final response = await _dio.getUri(_uri(host, port, '/info'));
      final info = PcInfo.fromJson(asJsonMap(response.data));
      if (info.apiVersion != 1) {
        throw const ApiError(ApiErrorCode.unsupportedApiVersion);
      }
      return info;
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException catch (error) {
      throw ApiError(ApiErrorCode.internalError, detail: error.message);
    }
  }

  @override
  Future<PairResult> pair({
    required String host,
    required int port,
    required String pairingToken,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.postUri(
        _uri(host, port, '/pair'),
        data: {
          'pairingToken': pairingToken,
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      return PairResult.fromJson(asJsonMap(response.data));
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException catch (error) {
      throw ApiError(ApiErrorCode.internalError, detail: error.message);
    }
  }

  @override
  Future<void> deleteDevice({
    required String host,
    required int port,
    required String sessionToken,
  }) async {
    try {
      await _dio.deleteUri(
        _uri(host, port, '/devices/me'),
        options: Options(headers: _authorization(sessionToken)),
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<Uint8List?> fetchMediaArt({
    required String host,
    required int port,
    required String sessionToken,
    int? artVersion,
  }) async {
    try {
      final query = artVersion != null ? {'t': '$artVersion'} : null;
      final response = await _dio.getUri<List<int>>(
        _uri(host, port, '/media/art', query),
        options: Options(
          headers: _authorization(sessionToken),
          responseType: ResponseType.bytes,
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw _mapDioError(error);
    }
  }

  @override
  Future<ShelfUploadResult> uploadToShelf({
    required String host,
    required int port,
    required String sessionToken,
    String? filePath,
    String? fileName,
    List<int>? fileBytes,
    String? text,
    void Function(int count, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final Map<String, dynamic> formMap = {};
      if (text != null && text.isNotEmpty) {
        formMap['text'] = text;
      }

      if (filePath != null) {
        final resolvedName = fileName ?? filePath.split(RegExp(r'[/\\]')).last;
        formMap['file'] = await MultipartFile.fromFile(
          filePath,
          filename: resolvedName,
        );
      } else if (fileBytes != null) {
        formMap['file'] = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName ?? 'upload.bin',
        );
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.postUri(
        _uri(host, port, '/shelf'),
        data: formData,
        options: Options(
          headers: _authorization(sessionToken),
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return ShelfUploadResult.fromJson(asJsonMap(response.data));
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException catch (error) {
      throw ApiError(ApiErrorCode.internalError, detail: error.message);
    }
  }

  @override
  Future<SystemStatus> fetchStatus({
    required String host,
    required int port,
    required String sessionToken,
  }) async {
    try {
      final response = await _dio.getUri(
        _uri(host, port, '/status'),
        options: Options(headers: _authorization(sessionToken)),
      );
      return SystemStatus.fromJson(asJsonMap(response.data));
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException catch (error) {
      throw ApiError(ApiErrorCode.internalError, detail: error.message);
    }
  }

  Map<String, String> _authorization(String sessionToken) {
    return {'Authorization': 'Bearer $sessionToken'};
  }

  Uri _uri(String host, int port, String path, [Map<String, dynamic>? query]) {
    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: path,
      queryParameters: query,
    );
  }

  ApiError _mapDioError(DioException error) {
    final response = error.response;
    if (response != null) {
      return ApiError.fromResponse(response.statusCode ?? 0, response.data);
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const ApiError(ApiErrorCode.timeout),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel ||
      DioExceptionType.badResponse ||
      DioExceptionType.unknown => const ApiError(ApiErrorCode.network),
    };
  }
}
