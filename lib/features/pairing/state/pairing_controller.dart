import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_error.dart';
import '../../../models/qr_payload.dart';
import 'pairing_providers.dart';
import 'pairing_state.dart';
import 'session_providers.dart';

class PairingController extends Notifier<PairingState> {
  @override
  PairingState build() => const PairingIdle();

  Future<void> pairWithQr(String raw, {String? deviceName}) async {
    try {
      final payload = QrPayload.parse(raw);
      await _pair(
        host: payload.host,
        port: payload.port,
        pairingToken: payload.token,
        expectedPcId: payload.pcId,
        deviceName: deviceName,
      );
    } on ApiError catch (error) {
      state = PairingFailure(error);
    }
  }

  Future<void> pairManually({
    required String host,
    required String port,
    required String token,
    String? deviceName,
  }) async {
    final normalizedHost = host.trim();
    if (!_isValidHost(normalizedHost)) {
      state = const PairingFailure(ApiError(ApiErrorCode.invalidHost));
      return;
    }

    final parsedPort = int.tryParse(port.trim());
    if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
      state = const PairingFailure(ApiError(ApiErrorCode.invalidPort));
      return;
    }

    final pairingToken = token.trim();
    if (pairingToken.isEmpty) {
      state = const PairingFailure(ApiError(ApiErrorCode.missingToken));
      return;
    }

    await _pair(
      host: normalizedHost,
      port: parsedPort,
      pairingToken: pairingToken,
      deviceName: deviceName,
    );
  }

  Future<void> _pair({
    required String host,
    required int port,
    required String pairingToken,
    String? expectedPcId,
    String? deviceName,
  }) async {
    state = const PairingConnecting(stage: PairingStage.verifying);

    try {
      final session = await ref
          .read(pairingRepositoryProvider)
          .pair(
            host: host,
            port: port,
            pairingToken: pairingToken,
            expectedPcId: expectedPcId,
            deviceName: deviceName,
            onWaitingApproval: () {
              state = const PairingConnecting(
                stage: PairingStage.waitingApproval,
              );
            },
          );

      state = PairingSuccess(session);
      ref.invalidate(savedSessionProvider);
    } on ApiError catch (error) {
      state = PairingFailure(error);
    } catch (_) {
      state = const PairingFailure(ApiError(ApiErrorCode.unknown));
    }
  }

  void reset() {
    state = const PairingIdle();
  }

  bool _isValidHost(String value) {
    if (value.isEmpty) return false;
    if (RegExp(r'\s').hasMatch(value)) return false;
    return !value.contains('/') &&
        !value.contains('?') &&
        !value.contains('#') &&
        !value.contains('@');
  }
}
