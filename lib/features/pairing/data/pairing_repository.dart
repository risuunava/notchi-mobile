import '../../../core/errors/api_error.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store.dart';
import '../../../models/qr_payload.dart';

class PairingRepository {
  PairingRepository({required this.api, required this.sessionStore});

  final NotchiApi api;
  final SessionStore sessionStore;

  Future<SavedSession> pairWithQr(
    QrPayload payload, {
    String? deviceName,
    void Function()? onWaitingApproval,
  }) {
    return pair(
      host: payload.host,
      port: payload.port,
      pairingToken: payload.token,
      expectedPcId: payload.pcId,
      deviceName: deviceName,
      onWaitingApproval: onWaitingApproval,
    );
  }

  Future<SavedSession> pair({
    required String host,
    required int port,
    required String pairingToken,
    String? expectedPcId,
    String? deviceName,
    void Function()? onWaitingApproval,
  }) async {
    final info = await api.fetchInfo(host: host, port: port);

    final expected = expectedPcId?.trim();
    if (expected != null && expected.isNotEmpty && expected != info.pcId) {
      throw const ApiError(ApiErrorCode.pcMismatch);
    }

    final identity = await sessionStore.ensureIdentity(
      preferredName: deviceName,
    );

    onWaitingApproval?.call();

    final result = await api.pair(
      host: host,
      port: port,
      pairingToken: pairingToken,
      deviceId: identity.deviceId,
      deviceName: identity.deviceName,
    );

    final session = SavedSession(
      sessionToken: result.sessionToken,
      pcId: result.pcId.isEmpty ? info.pcId : result.pcId,
      pcName: result.pcName.isEmpty ? info.pcName : result.pcName,
      host: host,
      port: port,
      apiVersion: info.apiVersion,
    );
    await sessionStore.saveSession(session);

    return session;
  }
}
