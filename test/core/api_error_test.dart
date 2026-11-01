import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/errors/api_error.dart';
import 'package:notchi_mobile/core/l10n/strings.dart';

void main() {
  group('ApiError.fromResponse', () {
    test('maps a wire error code', () {
      final error = ApiError.fromResponse(401, {
        'error': {
          'code': 'pairing_token_expired',
          'message': 'Token sudah dipakai.',
        },
      });

      expect(error.code, ApiErrorCode.pairingTokenExpired);
      expect(error.statusCode, 401);
      expect(error.detail, 'Token sudah dipakai.');
    });

    test('falls back to the HTTP status when the code is unknown', () {
      expect(
        ApiError.fromResponse(429, {
          'error': {'code': 'surprise'},
        }).code,
        ApiErrorCode.rateLimited,
      );
      expect(ApiError.fromResponse(413, null).code, ApiErrorCode.fileTooLarge);
      expect(
        ApiError.fromResponse(503, 'plain text').code,
        ApiErrorCode.internalError,
      );
    });

    test('maps server errors to internal_error', () {
      expect(
        ApiError.fromResponse(500, {
          'error': {'code': 'internal_error'},
        }).code,
        ApiErrorCode.internalError,
      );
    });
  });

  group('ApiError.message', () {
    test('returns localized text for both languages', () {
      const error = ApiError(ApiErrorCode.network);

      final indonesian = error.message(const AppStrings('id'));
      final english = error.message(const AppStrings('en'));

      expect(indonesian, isNotEmpty);
      expect(english, isNotEmpty);
      expect(indonesian, isNot(english));
    });

    test('covers every error code', () {
      for (final code in ApiErrorCode.values) {
        final message = ApiError(code).message(const AppStrings('id'));
        expect(message, isNotEmpty, reason: 'Missing message for $code');
      }
    });
  });
}
