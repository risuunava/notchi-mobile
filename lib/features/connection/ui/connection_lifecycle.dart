import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_store.dart';
import '../../pairing/state/session_providers.dart';
import '../state/connection_providers.dart';
import '../state/connection_status.dart';

class ConnectionLifecycle extends ConsumerStatefulWidget {
  const ConnectionLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConnectionLifecycle> createState() =>
      _ConnectionLifecycleState();
}

class _ConnectionLifecycleState extends ConsumerState<ConnectionLifecycle> {
  ProviderSubscription<AsyncValue<SavedSession?>>? _sessionSubscription;
  ProviderSubscription<ConnectionStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();

    _sessionSubscription = ref.listenManual<AsyncValue<SavedSession?>>(
      savedSessionProvider,
      (previous, next) {
        final controller = ref.read(connectionControllerProvider.notifier);
        next.whenData((session) {
          if (session == null) {
            controller.disconnect();
          } else {
            controller.connect(session);
          }
        });
      },
      fireImmediately: true,
    );

    _statusSubscription = ref.listenManual<ConnectionStatus>(
      connectionControllerProvider,
      (previous, next) {
        if (next is ConnectionStopped && _requiresRepair(next.reason)) {
          unawaited(_clearSession());
        }
      },
    );
  }

  bool _requiresRepair(ConnectionStopReason reason) {
    return reason == ConnectionStopReason.revoked ||
        reason == ConnectionStopReason.unauthorized;
  }

  Future<void> _clearSession() async {
    await ref.read(sessionStoreProvider).clearSession();
    ref.invalidate(savedSessionProvider);
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    _statusSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
