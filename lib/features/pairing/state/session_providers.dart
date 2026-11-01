import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_store.dart';

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => const FlutterSecureKeyValueStore(),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(ref.watch(keyValueStoreProvider)),
);

final savedSessionProvider = FutureProvider<SavedSession?>(
  (ref) => ref.watch(sessionStoreProvider).readSession(),
);
