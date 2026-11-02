import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../pairing/state/session_providers.dart';
import '../../pairing/ui/connect_first_card.dart';
import '../model/shelf_item.dart';
import '../state/shelf_controller.dart';
import 'drop_shelf_card.dart';

class ShelfPage extends ConsumerWidget {
  const ShelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final session = ref.watch(savedSessionProvider);

    return SafeArea(
      child: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildBody(context, ref, strings),
        data: (value) =>
            _buildBody(context, ref, strings, connected: value != null),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings, {
    bool connected = false,
  }) {
    final history = ref.watch(shelfControllerProvider).history;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        Text(
          strings.navFolder,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          strings.folderSubtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        if (!connected)
          const ConnectFirstCard()
        else ...[
          const DropShelfCard(),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.droppedFilesTitle,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(shelfControllerProvider.notifier)
                        .clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.historyCleared)),
                      );
                    }
                  },
                  child: Text(strings.clearHistory),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (history.isEmpty)
            _EmptyHistory(strings: strings)
          else
            ...history.map((entry) => _HistoryTile(entry: entry)),
        ],
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.soft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.folderOpen,
              size: 22,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.noDroppedFiles,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.noDroppedFilesHint,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final ShelfHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              entry.isText ? LucideIcons.fileText : LucideIcons.file,
              size: 19,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name.isEmpty ? '—' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(entry),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(ShelfHistoryEntry entry) {
    final parts = <String>[];
    if (entry.isText) {
      parts.add('Text');
    } else if (entry.size != null) {
      parts.add(_formatBytes(entry.size!));
    }
    parts.add(_formatDate(entry.createdAt));
    return parts.join(' • ');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
