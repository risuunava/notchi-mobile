import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../state/shelf_controller.dart';

class DropShelfCard extends ConsumerStatefulWidget {
  const DropShelfCard({super.key});

  @override
  ConsumerState<DropShelfCard> createState() => _DropShelfCardState();
}

class _DropShelfCardState extends ConsumerState<DropShelfCard> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendFile() async {
    final files = await FilePicker.pickFiles();
    if (files.isNotEmpty) {
      final file = files.first;
      final localPath = file.path;
      if (localPath != null) {
        await ref.read(shelfControllerProvider.notifier).sendFile(
          filePath: localPath,
          fileName: file.name,
        );
      } else {
        final bytes = await file.xFile.readAsBytes();
        await ref.read(shelfControllerProvider.notifier).sendFile(
          filePath: '',
          fileName: file.name,
          fileBytes: bytes,
        );
      }
    }
  }

  void _showSendTextDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    _textController.clear();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.sendText),
        content: TextField(
          controller: _textController,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: strings.textToShelfHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(dialogCtx).pop();
                ref.read(shelfControllerProvider.notifier).sendText(text);
              }
            },
            child: Text(strings.send),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final shelfState = ref.watch(shelfControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.drive_file_move_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  strings.shelfTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shelfState.status == ShelfUploadStatus.uploading) ...[
              Text(
                strings.uploading,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: shelfState.progress > 0 ? shelfState.progress : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      ref.read(shelfControllerProvider.notifier).cancel(),
                  child: Text(strings.cancel),
                ),
              ),
            ] else ...[
              if (shelfState.status == ShelfUploadStatus.success) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${strings.uploadSuccess}: ${shelfState.lastResult?.name ?? ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (shelfState.status == ShelfUploadStatus.error) ...[
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shelfState.error?.message(strings) ??
                            strings.uploadFailed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickAndSendFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(strings.sendFile),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSendTextDialog(context),
                      icon: const Icon(Icons.note_alt_outlined),
                      label: Text(strings.sendText),
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
