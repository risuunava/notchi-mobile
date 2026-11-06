import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../state/volume_controller.dart';

class VolumeCard extends ConsumerStatefulWidget {
  const VolumeCard({super.key});

  @override
  ConsumerState<VolumeCard> createState() => _VolumeCardState();
}

class _VolumeCardState extends ConsumerState<VolumeCard> {
  double? _dragLevel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final volume = ref.watch(volumeControllerProvider);
    final connected =
        ref.watch(connectionControllerProvider) is ConnectionConnected;

    final level = (_dragLevel ?? volume.level).clamp(0.0, 1.0);
    final percent = (level * 100).round();
    final muted = volume.muted;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: connected
                      ? () => ref
                            .read(volumeControllerProvider.notifier)
                            .toggleMute()
                      : null,
                  tooltip: muted ? strings.volumeUnmute : strings.volumeMute,
                  iconSize: 19,
                  padding: EdgeInsets.zero,
                  color: muted ? AppColors.muted : AppColors.ink,
                  icon: Icon(muted ? LucideIcons.volumeX : LucideIcons.volume2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.volumeTitle,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      muted ? strings.volumeMuted : strings.volumeDescription,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: level,
              onChanged: connected
                  ? (value) => setState(() => _dragLevel = value)
                  : null,
              onChangeEnd: connected
                  ? (value) {
                      ref
                          .read(volumeControllerProvider.notifier)
                          .setLevel(value);
                      setState(() => _dragLevel = null);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
