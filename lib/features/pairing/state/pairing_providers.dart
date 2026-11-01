import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/pairing_repository.dart';
import 'pairing_controller.dart';
import 'pairing_state.dart';
import 'session_providers.dart';

final apiClientProvider = Provider<NotchiApi>((ref) => ApiClient());

final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => PairingRepository(
    api: ref.watch(apiClientProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  ),
);

final pairingControllerProvider =
    NotifierProvider<PairingController, PairingState>(PairingController.new);
