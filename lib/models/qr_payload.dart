import '../core/errors/api_error.dart';

class QrPayload {
  const QrPayload({
    required this.host,
    required this.port,
    required this.token,
    required this.pcId,
    required this.pcName,
    required this.apiVersion,
  });

  static const supportedApiVersion = 1;
  static const _defaultPcName = 'PC Notchi';

  final String host;
  final int port;
  final String token;
  final String pcId;
  final String pcName;
  final int apiVersion;

  factory QrPayload.parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'notchi' || uri.host != 'pair') {
      throw const ApiError(ApiErrorCode.invalidQr, detail: 'unexpected_uri');
    }

    final params = uri.queryParameters;

    final host = params['host']?.trim() ?? '';
    if (!_isValidHost(host)) {
      throw const ApiError(ApiErrorCode.invalidQr, detail: 'invalid_host');
    }

    final port = int.tryParse(params['port']?.trim() ?? '');
    if (port == null || port < 1 || port > 65535) {
      throw const ApiError(ApiErrorCode.invalidQr, detail: 'invalid_port');
    }

    final token = params['token']?.trim() ?? '';
    if (token.isEmpty) {
      throw const ApiError(ApiErrorCode.invalidQr, detail: 'missing_token');
    }

    final pcId = params['pc']?.trim() ?? '';
    if (pcId.isEmpty) {
      throw const ApiError(ApiErrorCode.invalidQr, detail: 'missing_pc');
    }

    final version =
        int.tryParse(params['v']?.trim() ?? '') ?? supportedApiVersion;
    if (version != supportedApiVersion) {
      throw const ApiError(ApiErrorCode.unsupportedApiVersion);
    }

    final name = params['name']?.trim();

    return QrPayload(
      host: host,
      port: port,
      token: token,
      pcId: pcId,
      pcName: name == null || name.isEmpty ? _defaultPcName : name,
      apiVersion: version,
    );
  }

  static bool _isValidHost(String value) {
    if (value.isEmpty) return false;
    if (RegExp(r'\s').hasMatch(value)) return false;
    return !value.contains('/') &&
        !value.contains('?') &&
        !value.contains('#') &&
        !value.contains('@');
  }
}
