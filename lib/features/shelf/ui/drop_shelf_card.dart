import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../state/shelf_controller.dart';

class DropShelfCard extends ConsumerStatefulWidget {
  const DropShelfCard({super.key});

  @override
  ConsumerState<DropShelfCard> createState() => _DropShelfCardState();
}

class _DropShelfCardState extends ConsumerState<DropShelfCard> {
  Future<void> _pickAndSendFile() async {
    final files = await FilePicker.pickFiles();
    if (files.isNotEmpty) {
      final file = files.first;
      final localPath = file.path;
      if (localPath != null) {
        await ref
            .read(shelfControllerProvider.notifier)
            .sendFile(filePath: localPath, fileName: file.name);
      } else {
        final bytes = await file.xFile.readAsBytes();
        await ref
            .read(shelfControllerProvider.notifier)
            .sendFile(filePath: '', fileName: file.name, fileBytes: bytes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final shelfState = ref.watch(shelfControllerProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  LucideIcons.uploadCloud,
                  size: 23,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.shelfTitle,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.dropShelfHint,
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
          const SizedBox(height: 18),
          _buildActions(context, strings, shelfState),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    AppStrings strings,
    ShelfUploadState shelfState,
  ) {
    if (shelfState.status == ShelfUploadStatus.downloading) {
      final progress = shelfState.progress;
      final fileName = shelfState.incomingFileName ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.download, size: 17, color: AppColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName.isNotEmpty
                      ? '${strings.receivingFileFromPc} $fileName'
                      : strings.downloading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                progress > 0 ? '${(progress * 100).round()}%' : '...',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  ref.read(shelfControllerProvider.notifier).cancel(),
              child: Text(strings.cancel),
            ),
          ),
        ],
      );
    }

    if (shelfState.status == ShelfUploadStatus.uploading) {
      final progress = shelfState.progress;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.upload, size: 17, color: AppColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.uploading,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                progress > 0 ? '${(progress * 100).round()}%' : '...',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  ref.read(shelfControllerProvider.notifier).cancel(),
              child: Text(strings.cancel),
            ),
          ),
        ],
      );
    }

    final isIncomingLast = shelfState.history.isNotEmpty &&
        shelfState.history.first.isIncoming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shelfState.status == ShelfUploadStatus.success) ...[
          Row(
            children: [
              const Icon(
                LucideIcons.checkCircle,
                size: 17,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isIncomingLast ? strings.downloadSuccess : strings.uploadSuccess}: ${shelfState.lastResult?.name ?? ""}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else if (shelfState.status == ShelfUploadStatus.error) ...[
          Row(
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 17,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shelfState.error?.message(strings) ?? strings.uploadFailed,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        FilledButton.icon(
          onPressed: _pickAndSendFile,
          icon: const Icon(LucideIcons.uploadCloud, size: 17),
          label: Text(strings.sendFile),
        ),
      ],
    );
  }
}
