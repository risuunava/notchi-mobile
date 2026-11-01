import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../state/pairing_providers.dart';
import '../state/pairing_state.dart';

class PairingProgressScreen extends ConsumerStatefulWidget {
  const PairingProgressScreen.qr({super.key, required this.raw})
    : host = null,
      port = null,
      token = null;

  const PairingProgressScreen.manual({
    super.key,
    required this.host,
    required this.port,
    required this.token,
  }) : raw = null;

  final String? raw;
  final String? host;
  final String? port;
  final String? token;

  @override
  ConsumerState<PairingProgressScreen> createState() =>
      _PairingProgressScreenState();
}

class _PairingProgressScreenState extends ConsumerState<PairingProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  void _start() {
    final controller = ref.read(pairingControllerProvider.notifier);
    controller.reset();

    final raw = widget.raw;
    if (raw != null) {
      unawaited(controller.pairWithQr(raw));
      return;
    }

    unawaited(
      controller.pairManually(
        host: widget.host ?? '',
        port: widget.port ?? '',
        token: widget.token ?? '',
      ),
    );
  }

  void _cancel() {
    ref.read(pairingControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  void _finish() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(pairingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.connectingTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: _buildBody(strings, state)),
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings strings, PairingState state) {
    return switch (state) {
      PairingIdle() ||
      PairingConnecting(stage: PairingStage.verifying) => _StatusView(
        title: strings.connectingTitle,
        body: strings.verifyingPc,
        actionLabel: strings.cancel,
        onAction: _cancel,
      ),
      PairingConnecting(stage: PairingStage.waitingApproval) => _StatusView(
        title: strings.waitingTitle,
        body: strings.waitingBody,
        actionLabel: strings.cancel,
        onAction: _cancel,
      ),
      PairingSuccess(session: final session) => _ResultView(
        icon: Icons.check_circle,
        color: Theme.of(context).colorScheme.primary,
        title: strings.successTitle,
        body: strings.successBody,
        primaryLabel: strings.done,
        onPrimary: _finish,
        detail: '${session.pcName} · ${session.host}:${session.port}',
      ),
      PairingFailure(error: final error) => _ResultView(
        icon: Icons.error,
        color: Theme.of(context).colorScheme.error,
        title: strings.errorTitle,
        body: error.message(strings),
        primaryLabel: strings.retry,
        onPrimary: _start,
        secondaryLabel: strings.back,
        onSecondary: _cancel,
      ),
    };
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 32),
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = secondaryLabel;
    final secondaryAction = onSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (detail != null) ...[
          const SizedBox(height: 12),
          Text(
            detail!,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        if (secondary != null && secondaryAction != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: secondaryAction, child: Text(secondary)),
        ],
      ],
    );
  }
}
