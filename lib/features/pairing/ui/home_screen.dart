import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_error.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/storage/secure_store.dart';
import '../../connection/ui/connection_indicator.dart';
import '../../media/ui/media_player_card.dart';
import '../../shelf/ui/drop_shelf_card.dart';
import '../../status/ui/system_status_card.dart';
import '../state/pairing_providers.dart';
import '../state/session_providers.dart';
import 'manual_connect_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final session = ref.watch(savedSessionProvider);

    final showIndicator = session.asData?.value != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        actions: [
          if (showIndicator)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: ConnectionIndicator()),
            ),
        ],
      ),
      body: SafeArea(
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _NotPairedView(strings: strings),
          data: (value) => value == null
              ? _NotPairedView(strings: strings)
              : _ConnectedView(strings: strings, session: value),
        ),
      ),
    );
  }
}

class _NotPairedView extends StatelessWidget {
  const _NotPairedView({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              strings.notPairedTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              strings.notPairedBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _open(context, const ScanScreen()),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(strings.scanQr),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _open(context, const ManualConnectScreen()),
              icon: const Icon(Icons.keyboard),
              label: Text(strings.manualConnect),
            ),
            const SizedBox(height: 24),
            Text(
              strings.homeSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _ConnectedView extends ConsumerWidget {
  const _ConnectedView({required this.strings, required this.session});

  final AppStrings strings;
  final SavedSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.connectedTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  strings.connectedTo(session.pcName),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.host}:${session.port}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const MediaPlayerCard(),
        const SizedBox(height: 16),
        const DropShelfCard(),
        const SizedBox(height: 16),
        const SystemStatusCard(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _forget(context, ref),
          icon: const Icon(Icons.link_off),
          label: Text(strings.forgetDevice),
        ),
        const SizedBox(height: 24),
        Text(
          strings.homeSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _forget(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.forgetTitle),
        content: Text(strings.forgetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.forgetDevice),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    var remoteFailed = false;
    try {
      await ref
          .read(apiClientProvider)
          .deleteDevice(
            host: session.host,
            port: session.port,
            sessionToken: session.sessionToken,
          );
    } on ApiError catch (error) {
      remoteFailed = error.code != ApiErrorCode.invalidToken;
    } catch (_) {
      remoteFailed = true;
    }

    await ref.read(sessionStoreProvider).clearSession();
    ref.invalidate(savedSessionProvider);

    if (remoteFailed && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.forgetRemoteFailed)));
    }
  }
}
