import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../state/status_controller.dart';

class SystemStatusCard extends ConsumerStatefulWidget {
  const SystemStatusCard({super.key});

  @override
  ConsumerState<SystemStatusCard> createState() => _SystemStatusCardState();
}

class _SystemStatusCardState extends ConsumerState<SystemStatusCard> {
  SystemStatusController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final ctrl = ref.read(systemStatusControllerProvider.notifier);
      ctrl.subscribe();
      _controller = ctrl;
    }
  }

  @override
  void dispose() {
    _controller?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(systemStatusControllerProvider);

    if (status == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  strings.statusTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (status.cpuPercent != null)
                  Expanded(
                    child: _MetricTile(
                      label: strings.cpuUsage,
                      value: '${status.cpuPercent!.toStringAsFixed(0)}%',
                      progress: status.cpuPercent! / 100,
                      icon: Icons.memory,
                    ),
                  ),
                if (status.ramPercent != null)
                  Expanded(
                    child: _MetricTile(
                      label: strings.ramUsage,
                      value: '${status.ramPercent!.toStringAsFixed(0)}%',
                      progress: status.ramPercent! / 100,
                      icon: Icons.speed,
                    ),
                  ),
                if (status.diskPercent != null)
                  Expanded(
                    child: _MetricTile(
                      label: strings.diskUsage,
                      value: '${status.diskPercent!.toStringAsFixed(0)}%',
                      progress: status.diskPercent! / 100,
                      icon: Icons.storage,
                    ),
                  ),
              ],
            ),
            if (status.battery != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    status.battery!.charging
                        ? Icons.battery_charging_full
                        : Icons.battery_std,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${strings.battery}: ${status.battery!.percent}% (${status.battery!.charging ? strings.charging : strings.notCharging})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.progress,
    required this.icon,
  });

  final String label;
  final String value;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
