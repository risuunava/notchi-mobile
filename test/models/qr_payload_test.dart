import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/core/errors/api_error.dart';
import 'package:notchi_mobile/models/qr_payload.dart';

Matcher throwsApiError(ApiErrorCode code) {
  return throwsA(isA<ApiError>().having((error) => error.code, 'code', code));
}

void main() {
  group('QrPayload.parse', () {
    test('parses a valid pairing URI', () {
      final payload = QrPayload.parse(
        'notchi://pair?host=192.168.1.10&port=8765&token=tok-1&pc=pc-1&name=LAPTOP-FARIS&v=1',
      );

      expect(payload.host, '192.168.1.10');
      expect(payload.port, 8765);
      expect(payload.token, 'tok-1');
      expect(payload.pcId, 'pc-1');
      expect(payload.pcName, 'LAPTOP-FARIS');
      expect(payload.apiVersion, 1);
    });

    test('decodes a URL encoded PC name', () {
      final payload = QrPayload.parse(
        'notchi://pair?host=10.0.0.2&port=9000&token=t&pc=p&name=Kamar%20Faris',
      );

      expect(payload.pcName, 'Kamar Faris');
    });

    test('defaults the PC name when it is missing', () {
      final payload = QrPayload.parse(
        'notchi://pair?host=10.0.0.2&port=9000&token=t&pc=p',
      );

      expect(payload.pcName, 'PC Notchi');
      expect(payload.apiVersion, 1);
    });

    test('rejects an unknown URI scheme', () {
      expect(
        () => QrPayload.parse('https://example.com/pair?token=t'),
        throwsApiError(ApiErrorCode.invalidQr),
      );
    });

    test('rejects a missing host', () {
      expect(
        () => QrPayload.parse('notchi://pair?port=8765&token=t&pc=p'),
        throwsApiError(ApiErrorCode.invalidQr),
      );
    });

    test('rejects a host containing a path', () {
      expect(
        () => QrPayload.parse(
          'notchi://pair?host=10.0.0.2/evil&port=8765&token=t&pc=p',
        ),
        throwsApiError(ApiErrorCode.invalidQr),
      );
    });

    test('rejects an invalid port', () {
      expect(
        () => QrPayload.parse(
          'notchi://pair?host=10.0.0.2&port=70000&token=t&pc=p',
        ),
        throwsApiError(ApiErrorCode.invalidQr),
      );
    });

    test('rejects a missing token', () {
      expect(
        () => QrPayload.parse('notchi://pair?host=10.0.0.2&port=8765&pc=p'),
        throwsApiError(ApiErrorCode.invalidQr),
      );
    });

    test('rejects a missing PC id', () {
      expect(
        () => QrPayload.parse('notchi://pair?host=10.0.0.2&port=8765&token=t'),
        throwsApiError(ApiErrorCode.invalidQr),
      );
    });

    test('rejects an unsupported API version', () {
      expect(
        () => QrPayload.parse(
          'notchi://pair?host=10.0.0.2&port=8765&token=t&pc=p&v=2',
        ),
        throwsApiError(ApiErrorCode.unsupportedApiVersion),
      );
    });
  });
}
