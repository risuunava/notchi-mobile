import 'package:dio/dio.dart';

import '../errors/api_error.dart';
import '../json/json_utils.dart';
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
}

class ApiClient implements NotchiApi {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 65),
              receiveTimeout: const Duration(seconds: 65),
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

  Uri _uri(String host, int port, String path) {
    return Uri(scheme: 'http', host: host, port: port, path: path);
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
