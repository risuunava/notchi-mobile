import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
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
    final theme = Theme.of(context);
    final media = ref.watch(mediaControllerProvider);
    final artBytes = ref.watch(mediaArtProvider);

    if (media == null || !media.available) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.music_off_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.mediaNoMedia,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.mediaNoMediaHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final duration = media.durationSeconds;
    final currentPos = _draggingPosition ?? media.positionSeconds;
    final progress = duration > 0 ? (currentPos / duration).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: theme.colorScheme.primaryContainer,
                    child: artBytes != null
                        ? Image.memory(
                            artBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _artPlaceholder(theme),
                          )
                        : _artPlaceholder(theme),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (media.sourceApp.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            media.sourceApp,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        media.title.isNotEmpty ? media.title : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        media.artist.isNotEmpty ? media.artist : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (media.canSeek && duration > 0) ...[
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(currentPos),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _formatTime(duration),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: strings.mediaPrevious,
                  iconSize: 32,
                  onPressed: () {
                    ref.read(mediaControllerProvider.notifier).previous();
                  },
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  tooltip: media.playing ? strings.mediaPause : strings.mediaPlay,
                  iconSize: 40,
                  onPressed: () {
                    ref.read(mediaControllerProvider.notifier).toggle();
                  },
                  icon: Icon(
                    media.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: strings.mediaNext,
                  iconSize: 32,
                  onPressed: () {
                    ref.read(mediaControllerProvider.notifier).next();
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _artPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: 32,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
