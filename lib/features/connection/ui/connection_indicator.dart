import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../state/connection_providers.dart';
import '../state/connection_status.dart';

class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  static const _online = Color(0xFF2ECC71);
  static const _connecting = Color(0xFFF1C40F);
  static const _reconnecting = Color(0xFFF39C12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(connectionControllerProvider);

    final (color, label) = switch (status) {
      ConnectionConnected() => (_online, strings.connectionOnline),
      ConnectionConnecting() => (_connecting, strings.connectionConnecting),
      ConnectionReconnecting() => (
        _reconnecting,
        strings.connectionReconnecting,
      ),
      ConnectionStopped(:final reason) => (
        theme.colorScheme.error,
        switch (reason) {
          ConnectionStopReason.revoked => strings.connectionRevoked,
          ConnectionStopReason.disabled => strings.connectionDisabled,
          ConnectionStopReason.unauthorized => strings.connectionUnauthorized,
        },
      ),
      ConnectionIdle() => (
        theme.colorScheme.outline,
        strings.connectionOffline,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
