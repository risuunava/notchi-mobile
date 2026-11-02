import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../pairing/state/session_providers.dart';
import '../model/note.dart';

class NotesController extends AsyncNotifier<List<Note>> {
  static const _storageKey = 'notchi.notes';
  static const _uuid = Uuid();

  @override
  Future<List<Note>> build() async {
    try {
      final raw = await ref.read(keyValueStoreProvider).read(_storageKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final notes = decoded
          .whereType<Map>()
          .map(
            (item) => Note.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((note) => note.id.isNotEmpty)
          .toList();

      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveNote({
    String? id,
    required String title,
    required String body,
  }) async {
    final notes = List<Note>.of(state.value ?? const []);
    final now = DateTime.now();
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();

    if (trimmedTitle.isEmpty && trimmedBody.isEmpty) return;

    final index = notes.indexWhere((note) => note.id == id);
    if (index >= 0) {
      notes[index] = Note(
        id: notes[index].id,
        title: trimmedTitle,
        body: trimmedBody,
        updatedAt: now,
      );
    } else {
      notes.add(
        Note(
          id: _uuid.v4(),
          title: trimmedTitle,
          body: trimmedBody,
          updatedAt: now,
        ),
      );
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncData(notes);
    await _persist(notes);
  }

  Future<void> deleteNote(String id) async {
    final notes = (state.value ?? const [])
        .where((note) => note.id != id)
        .toList();
    state = AsyncData(notes);
    await _persist(notes);
  }

  Future<void> _persist(List<Note> notes) async {
    try {
      await ref
          .read(keyValueStoreProvider)
          .write(
            _storageKey,
            jsonEncode(notes.map((note) => note.toJson()).toList()),
          );
    } catch (_) {
      // Notes remain available in memory when persistence fails.
    }
  }
}

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<Note>>(NotesController.new);
