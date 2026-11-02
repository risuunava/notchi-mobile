import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../pairing/state/session_providers.dart';
import '../../shelf/state/shelf_controller.dart';
import '../model/note.dart';
import '../state/notes_controller.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final notes = ref.watch(notesControllerProvider);

    return SafeArea(
      child: Stack(
        children: [
          notes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _NotesContent(strings: strings, notes: const []),
            data: (value) => _NotesContent(
              strings: strings,
              notes: value,
              onEdit: (note) => _openEditor(context, ref, note: note),
              onDelete: (note) => _deleteNote(context, ref, note),
              onSend: (note) => _sendNote(context, ref, note),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(LucideIcons.plus, size: 19),
              label: Text(strings.newNote),
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Note? note,
  }) async {
    final draft = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _NoteEditorSheet(note: note),
    );

    if (draft == null) return;

    await ref
        .read(notesControllerProvider.notifier)
        .saveNote(id: note?.id, title: draft.title, body: draft.body);
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteNoteTitle),
        content: Text(strings.deleteNoteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(notesControllerProvider.notifier).deleteNote(note.id);
  }

  Future<void> _sendNote(BuildContext context, WidgetRef ref, Note note) async {
    final strings = AppStrings.of(context);
    final session = ref.read(savedSessionProvider).asData?.value;
    if (session == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.noteSendFailed)));
      return;
    }

    final text = [
      note.title,
      note.body,
    ].where((part) => part.trim().isNotEmpty).join('\n\n');

    await ref.read(shelfControllerProvider.notifier).sendText(text);
    if (!context.mounted) return;

    final sent =
        ref.read(shelfControllerProvider).status == ShelfUploadStatus.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent ? strings.noteSentToPc : strings.noteSendFailed),
      ),
    );
  }
}

class _NotesContent extends StatelessWidget {
  const _NotesContent({
    required this.strings,
    required this.notes,
    this.onEdit,
    this.onDelete,
    this.onSend,
  });

  final AppStrings strings;
  final List<Note> notes;
  final void Function(Note note)? onEdit;
  final void Function(Note note)? onDelete;
  final void Function(Note note)? onSend;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        Text(
          strings.notesTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          strings.notesSubtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        if (notes.isEmpty)
          _EmptyNotes(strings: strings)
        else
          ...notes.map(
            (note) => _NoteTile(
              note: note,
              strings: strings,
              onTap: onEdit == null ? null : () => onEdit!(note),
              onSend: onSend == null ? null : () => onSend!(note),
              onDelete: onDelete == null ? null : () => onDelete!(note),
            ),
          ),
      ],
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.soft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.stickyNote,
              size: 26,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            strings.noteEmpty,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.noteEmptyHint,
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

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.strings,
    this.onTap,
    this.onSend,
    this.onDelete,
  });

  final Note note;
  final AppStrings strings;
  final VoidCallback? onTap;
  final VoidCallback? onSend;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty
        ? note.body.trim().split('\n').first
        : note.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.stickyNote,
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
                      title.isEmpty ? '—' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (note.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        note.body.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(note.updatedAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSend,
                tooltip: strings.sendToPc,
                iconSize: 19,
                color: AppColors.ink,
                icon: const Icon(LucideIcons.send),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: strings.delete,
                iconSize: 19,
                color: AppColors.danger,
                icon: const Icon(LucideIcons.trash2),
              ),
            ],
          ),
        ),
      ),
    );
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

class _NoteDraft {
  const _NoteDraft({required this.title, required this.body});

  final String title;
  final String body;
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({this.note});

  final Note? note;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.note == null ? strings.newNote : strings.edit,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: strings.noteTitleHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: strings.noteBodyHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                _NoteDraft(
                  title: _titleController.text,
                  body: _bodyController.text,
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(strings.saveNote),
          ),
        ],
      ),
    );
  }
}
