import '../../../core/errors/api_error.dart';
import '../../../core/storage/secure_store.dart';

sealed class PairingState {
  const PairingState();
}

class PairingIdle extends PairingState {
  const PairingIdle();
}

enum PairingStage { verifying, waitingApproval }

class PairingConnecting extends PairingState {
  const PairingConnecting({required this.stage});

  final PairingStage stage;
}

class PairingSuccess extends PairingState {
  const PairingSuccess(this.session);

  final SavedSession session;
}

class PairingFailure extends PairingState {
  const PairingFailure(this.error);

  final ApiError error;
}
