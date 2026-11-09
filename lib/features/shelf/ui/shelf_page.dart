import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../pairing/state/session_providers.dart';
import '../../pairing/ui/connect_first_card.dart';
import '../model/shelf_item.dart';
import '../state/shelf_controller.dart';
import 'drop_shelf_card.dart';

enum ShelfFilter {
  all,
  incoming,
  outgoing,
}

class ShelfPage extends ConsumerStatefulWidget {
  const ShelfPage({super.key});

  @override
  ConsumerState<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends ConsumerState<ShelfPage> {
  ShelfFilter _filter = ShelfFilter.all;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final session = ref.watch(savedSessionProvider);

    return SafeArea(
      child: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildBody(context, strings),
        data: (value) =>
            _buildBody(context, strings, connected: value != null),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppStrings strings, {
    bool connected = false,
  }) {
    final allHistory = ref.watch(shelfControllerProvider).history;

    final filteredHistory = switch (_filter) {
      ShelfFilter.all => allHistory,
      ShelfFilter.incoming => allHistory.where((e) => e.isIncoming).toList(),
      ShelfFilter.outgoing => allHistory.where((e) => !e.isIncoming).toList(),
    };

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
              if (allHistory.isNotEmpty)
                _buildFilterButton(strings),
            ],
          ),
          const SizedBox(height: 10),
          if (allHistory.isEmpty)
            _EmptyHistory(strings: strings)
          else if (filteredHistory.isEmpty)
            _EmptyFilteredHistory(
              strings: strings,
              filter: _filter,
              onReset: () => setState(() => _filter = ShelfFilter.all),
            )
          else
            ...filteredHistory.map((entry) => _HistoryTile(entry: entry)),
        ],
      ],
    );
  }

  Widget _buildFilterButton(AppStrings strings) {
    final isFiltered = _filter != ShelfFilter.all;

    return PopupMenuButton<ShelfFilter>(
      initialValue: _filter,
      tooltip: strings.filterTitle,
      color: AppColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (filter) {
        setState(() => _filter = filter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isFiltered ? AppColors.ink : AppColors.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _filter == ShelfFilter.incoming
                  ? LucideIcons.arrowDownToLine
                  : _filter == ShelfFilter.outgoing
                      ? LucideIcons.arrowUpFromLine
                      : LucideIcons.slidersHorizontal,
              size: 13,
              color: isFiltered ? Colors.white : AppColors.ink,
            ),
            const SizedBox(width: 6),
            Text(
              _filterLabel(_filter, strings),
              style: TextStyle(
                color: isFiltered ? Colors.white : AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 13,
              color: isFiltered ? Colors.white70 : AppColors.muted,
            ),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: ShelfFilter.all,
          child: Row(
            children: [
              Icon(
                LucideIcons.layers,
                size: 15,
                color: _filter == ShelfFilter.all
                    ? AppColors.ink
                    : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.filterAll,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: _filter == ShelfFilter.all
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_filter == ShelfFilter.all)
                const Icon(LucideIcons.check, size: 15, color: AppColors.ink),
            ],
          ),
        ),
        PopupMenuItem(
          value: ShelfFilter.incoming,
          child: Row(
            children: [
              Icon(
                LucideIcons.arrowDownToLine,
                size: 15,
                color: _filter == ShelfFilter.incoming
                    ? AppColors.ink
                    : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.filterIncoming,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: _filter == ShelfFilter.incoming
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_filter == ShelfFilter.incoming)
                const Icon(LucideIcons.check, size: 15, color: AppColors.ink),
            ],
          ),
        ),
        PopupMenuItem(
          value: ShelfFilter.outgoing,
          child: Row(
            children: [
              Icon(
                LucideIcons.arrowUpFromLine,
                size: 15,
                color: _filter == ShelfFilter.outgoing
                    ? AppColors.ink
                    : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.filterOutgoing,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: _filter == ShelfFilter.outgoing
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_filter == ShelfFilter.outgoing)
                const Icon(LucideIcons.check, size: 15, color: AppColors.ink),
            ],
          ),
        ),
      ],
    );
  }

  String _filterLabel(ShelfFilter filter, AppStrings strings) {
    return switch (filter) {
      ShelfFilter.all => strings.filterAll,
      ShelfFilter.incoming => strings.filterIncoming,
      ShelfFilter.outgoing => strings.filterOutgoing,
    };
  }
}

class _EmptyFilteredHistory extends StatelessWidget {
  const _EmptyFilteredHistory({
    required this.strings,
    required this.filter,
    required this.onReset,
  });

  final AppStrings strings;
  final ShelfFilter filter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final label = filter == ShelfFilter.incoming
        ? strings.filterIncoming
        : strings.filterOutgoing;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            filter == ShelfFilter.incoming
                ? LucideIcons.arrowDownToLine
                : LucideIcons.arrowUpFromLine,
            size: 26,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          Text(
            '${strings.noFilterResults} ($label)',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onReset,
            child: Text(strings.filterAll),
          ),
        ],
      ),
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

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final ShelfHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final isIncoming = entry.isIncoming;

    final fileIcon = entry.isText
        ? (isIncoming ? LucideIcons.messageSquare : LucideIcons.fileText)
        : (isIncoming
            ? LucideIcons.arrowDownToLine
            : LucideIcons.arrowUpFromLine);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
              fileIcon,
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
                  _metaLine(entry, strings),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              LucideIcons.ellipsisVertical,
              size: 18,
              color: AppColors.muted,
            ),
            tooltip: '',
            color: AppColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            onSelected: (action) {
              if (action == 'open') {
                _openEntry(context, entry);
              } else if (action == 'delete') {
                _confirmDelete(context, ref, entry);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.folderOpen,
                      size: 16,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      strings.open,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      strings.delete,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEntry(BuildContext context, ShelfHistoryEntry entry) async {
    final strings = AppStrings.of(context);

    if (entry.isText || (entry.content != null && entry.content!.isNotEmpty)) {
      final text =
          entry.content?.isNotEmpty == true ? entry.content! : entry.name;
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(entry.name.isEmpty ? strings.navNote : entry.name),
          content: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.ink,
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.copiedToClipboard)),
                );
              },
              icon: const Icon(LucideIcons.copy, size: 16),
              label: Text(strings.copyText),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(strings.close),
            ),
          ],
        ),
      );
      return;
    }

    final localPath = entry.filePath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        // Try to open with system app via OpenFilex (handles FileProvider on Android)
        final result = await OpenFilex.open(localPath);
        if (result.type == ResultType.done) return;
      }
    }

    // Fallback: show file details dialog
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(strings.fileDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.name.isEmpty ? '—' : entry.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _metaLine(entry, strings),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              entry.isIncoming
                  ? strings.fileReceivedFromPc
                  : strings.fileSentToPc,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
            if (localPath != null && localPath.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                localPath,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ShelfHistoryEntry entry,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(strings.deleteHistoryItemTitle),
        content: Text(strings.deleteHistoryItemBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(shelfControllerProvider.notifier)
          .deleteHistoryEntry(entry.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.historyItemDeleted)),
        );
      }
    }
  }

  String _metaLine(ShelfHistoryEntry entry, AppStrings strings) {
    final parts = <String>[];
    parts.add(entry.isIncoming ? strings.incomingFromPc : strings.sentToPc);
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
