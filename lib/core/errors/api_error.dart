import '../l10n/strings.dart';

enum ApiErrorCode {
  invalidQr,
  unsupportedApiVersion,
  pcMismatch,
  invalidHost,
  invalidPort,
  missingToken,
  badRequest,
  invalidToken,
  pairingTokenExpired,
  pairingDenied,
  featureDisabled,
  notFound,
  pairingTimeout,
  alreadyPaired,
  fileTooLarge,
  unsupportedMediaType,
  rateLimited,
  internalError,
  noMediaSession,
  network,
  timeout,
  unknown,
}

class ApiError implements Exception {
  const ApiError(this.code, {this.detail, this.statusCode});

  final ApiErrorCode code;
  final String? detail;
  final int? statusCode;

  factory ApiError.fromResponse(int statusCode, Object? body) {
    String? wireCode;
    String? wireMessage;

    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        wireCode = error['code']?.toString();
        wireMessage = error['message']?.toString();
      }
    }

    return ApiError(
      _fromWireCode(wireCode) ?? _fromStatusCode(statusCode),
      detail: wireMessage,
      statusCode: statusCode,
    );
  }

  static ApiErrorCode? _fromWireCode(String? code) {
    return switch (code) {
      'bad_request' => ApiErrorCode.badRequest,
      'invalid_token' => ApiErrorCode.invalidToken,
      'pairing_token_expired' => ApiErrorCode.pairingTokenExpired,
      'pairing_denied' => ApiErrorCode.pairingDenied,
      'feature_disabled' => ApiErrorCode.featureDisabled,
      'not_found' => ApiErrorCode.notFound,
      'pairing_timeout' => ApiErrorCode.pairingTimeout,
      'already_paired' => ApiErrorCode.alreadyPaired,
      'file_too_large' => ApiErrorCode.fileTooLarge,
      'unsupported_media_type' => ApiErrorCode.unsupportedMediaType,
      'rate_limited' => ApiErrorCode.rateLimited,
      'internal_error' => ApiErrorCode.internalError,
      'no_media_session' => ApiErrorCode.noMediaSession,
      _ => null,
    };
  }

  static ApiErrorCode _fromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 => ApiErrorCode.badRequest,
      401 => ApiErrorCode.invalidToken,
      404 => ApiErrorCode.notFound,
      408 => ApiErrorCode.pairingTimeout,
      409 => ApiErrorCode.alreadyPaired,
      413 => ApiErrorCode.fileTooLarge,
      415 => ApiErrorCode.unsupportedMediaType,
      429 => ApiErrorCode.rateLimited,
      >= 500 => ApiErrorCode.internalError,
      _ => ApiErrorCode.unknown,
    };
  }

  String message(AppStrings strings) {
    return switch (code) {
      ApiErrorCode.invalidQr => strings.errorInvalidQr,
      ApiErrorCode.unsupportedApiVersion => strings.errorUnsupportedVersion,
      ApiErrorCode.pcMismatch => strings.errorPcMismatch,
      ApiErrorCode.invalidHost => strings.invalidHost,
      ApiErrorCode.invalidPort => strings.invalidPort,
      ApiErrorCode.missingToken => strings.missingToken,
      ApiErrorCode.invalidToken => strings.errorInvalidToken,
      ApiErrorCode.pairingTokenExpired => strings.errorPairingExpired,
      ApiErrorCode.pairingDenied => strings.errorPairingDenied,
      ApiErrorCode.pairingTimeout => strings.errorPairingTimeout,
      ApiErrorCode.alreadyPaired => strings.errorAlreadyPaired,
      ApiErrorCode.rateLimited => strings.errorRateLimited,
      ApiErrorCode.featureDisabled => strings.errorFeatureDisabled,
      ApiErrorCode.network => strings.errorNetwork,
      ApiErrorCode.timeout => strings.errorTimeout,
      ApiErrorCode.fileTooLarge => strings.errorFileTooLarge,
      ApiErrorCode.badRequest ||
      ApiErrorCode.notFound ||
      ApiErrorCode.unsupportedMediaType ||
      ApiErrorCode.internalError ||
      ApiErrorCode.noMediaSession => strings.errorServer,
      ApiErrorCode.unknown => strings.errorUnknown,
    };
  }

  @override
  String toString() {
    return 'ApiError($code, statusCode: $statusCode, detail: $detail)';
  }
}
