import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../state/media_controller.dart';

class MediaPlayerCard extends ConsumerStatefulWidget {
  const MediaPlayerCard({super.key});

  @override
  ConsumerState<MediaPlayerCard> createState() => _MediaPlayerCardState();
}

class _MediaPlayerCardState extends ConsumerState<MediaPlayerCard> {
  double? _draggingPosition;

  String _formatTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) return '00:00';
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final media = ref.watch(mediaControllerProvider);
    final livePosition = ref.watch(mediaPositionProvider);
    final artBytes = ref.watch(mediaArtProvider);

    if (media == null || !media.available) {
      return const _EmptyMediaCard();
    }

    final duration = media.durationSeconds;
    final currentPos = _draggingPosition ?? livePosition;
    final progress = duration > 0
        ? (currentPos / duration).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: ColoredBox(
                    color: AppColors.soft,
                    child: artBytes != null
                        ? Image.memory(
                            artBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _ArtPlaceholder(),
                          )
                        : const _ArtPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title.isNotEmpty ? media.title : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      media.artist.isNotEmpty ? media.artist : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_brandFor(media.sourceApp) != null) ...[
                const SizedBox(width: 12),
                _SourceAppIcon(sourceApp: media.sourceApp),
              ],
            ],
          ),
          if (media.canSeek && duration > 0) ...[
            const SizedBox(height: 14),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: progress,
                onChanged: (value) {
                  setState(() {
                    _draggingPosition = value * duration;
                  });
                },
                onChangeEnd: (value) {
                  final target = value * duration;
                  ref.read(mediaControllerProvider.notifier).seek(target);
                  setState(() {
                    _draggingPosition = null;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(currentPos),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatTime(duration),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlIcon(
                icon: LucideIcons.skipBack,
                tooltip: strings.mediaPrevious,
                iconSize: 26,
                padding: const EdgeInsets.all(10),
                onPressed: () =>
                    ref.read(mediaControllerProvider.notifier).previous(),
              ),
              const SizedBox(width: 24),
              _ControlIcon(
                icon: media.playing ? LucideIcons.pause : LucideIcons.play,
                tooltip: media.playing ? strings.mediaPause : strings.mediaPlay,
                iconSize: 32,
                padding: const EdgeInsets.all(10),
                onPressed: () =>
                    ref.read(mediaControllerProvider.notifier).toggle(),
              ),
              const SizedBox(width: 24),
              _ControlIcon(
                icon: LucideIcons.skipForward,
                tooltip: strings.mediaNext,
                iconSize: 26,
                padding: const EdgeInsets.all(10),
                onPressed: () =>
                    ref.read(mediaControllerProvider.notifier).next(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(LucideIcons.music, size: 24, color: AppColors.muted),
    );
  }
}

class _SourceBrand {
  const _SourceBrand({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final FaIconData icon;
  final Color background;
  final Color foreground;
}

_SourceBrand? _brandFor(String sourceApp) {
  final app = sourceApp.toLowerCase();

  if (app.contains('spotify')) {
    return const _SourceBrand(
      icon: FontAwesomeIcons.spotify,
      background: Color(0xFF1DB954),
      foreground: Colors.white,
    );
  }

  if (app.contains('chrome')) {
    return const _SourceBrand(
      icon: FontAwesomeIcons.chrome,
      background: Color(0xFFEA4335),
      foreground: Colors.white,
    );
  }

  return null;
}

class _SourceAppIcon extends StatelessWidget {
  const _SourceAppIcon({required this.sourceApp});

  final String sourceApp;

  @override
  Widget build(BuildContext context) {
    final brand = _brandFor(sourceApp);
    if (brand == null) return const SizedBox.shrink();

    return Semantics(
      label: sourceApp,
      child: Tooltip(
        message: sourceApp,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: brand.background,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(brand.icon, size: 20, color: brand.foreground),
          ),
        ),
      ),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 20,
    this.padding = const EdgeInsets.all(8),
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      color: AppColors.ink,
      padding: padding,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon),
    );
  }
}

class _EmptyMediaCard extends StatelessWidget {
  const _EmptyMediaCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.music,
              size: 23,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.mediaNoMedia,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.mediaNoMediaHint,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
