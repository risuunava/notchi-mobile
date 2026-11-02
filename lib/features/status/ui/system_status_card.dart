import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
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
    final status = ref.watch(systemStatusControllerProvider);

    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.activity, size: 18, color: AppColors.muted),
            const SizedBox(width: 10),
            Text(
              strings.waitingPcStatus,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (status.cpuPercent != null)
                Expanded(
                  child: _Metric(
                    icon: LucideIcons.cpu,
                    label: strings.cpuUsage,
                    value: '${status.cpuPercent!.toStringAsFixed(0)}%',
                    progress: status.cpuPercent! / 100,
                  ),
                ),
              if (status.ramPercent != null)
                Expanded(
                  child: _Metric(
                    icon: LucideIcons.memoryStick,
                    label: strings.ramUsage,
                    value: '${status.ramPercent!.toStringAsFixed(0)}%',
                    progress: status.ramPercent! / 100,
                  ),
                ),
              if (status.diskPercent != null)
                Expanded(
                  child: _Metric(
                    icon: LucideIcons.hardDrive,
                    label: strings.diskUsage,
                    value: '${status.diskPercent!.toStringAsFixed(0)}%',
                    progress: status.diskPercent! / 100,
                  ),
                ),
            ],
          ),
          if (status.battery != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  status.battery!.charging
                      ? LucideIcons.batteryCharging
                      : LucideIcons.battery,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 7),
                Text(
                  '${strings.battery}: ${status.battery!.percent}% (${status.battery!.charging ? strings.charging : strings.notCharging})',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: clamped, minHeight: 4),
          ),
        ),
      ],
    );
  }
}
