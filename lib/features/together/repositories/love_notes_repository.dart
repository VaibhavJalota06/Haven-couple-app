import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../models/love_note_model.dart';

class LoveNotesRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  LoveNotesRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  final List<LoveNoteModel> _localNotes = [];
  final _notesController = StreamController<List<LoveNoteModel>>.broadcast();

  List<LoveNoteModel> getLocalLoveNotes(String relationshipId) {
    return List<LoveNoteModel>.unmodifiable(_localNotes);
  }

  /// Stream love notes for relationship in real-time
  Stream<List<LoveNoteModel>> getLoveNotesStream(String relationshipId) async* {
    yield _localNotes;
    if (relationshipId.isNotEmpty) {
      try {
        final stream = _client
            .from('love_notes')
            .stream(primaryKey: ['id'])
            .eq('relationship_id', relationshipId)
            .order('unlock_at', ascending: true)
            .map((data) {
              final remote = data.map((json) => LoveNoteModel.fromJson(json)).toList();
              if (remote.isNotEmpty) {
                _localNotes.clear();
                _localNotes.addAll(remote);
              }
              return _localNotes;
            });
        yield* stream;
      } catch (_) {
        yield* _notesController.stream;
      }
    } else {
      yield* _notesController.stream;
    }
  }

  /// Create and send a time-locked love note / capsule
  Future<LoveNoteModel> createLoveNote({
    required String relationshipId,
    required String title,
    required String content,
    required DateTime unlockAt,
  }) async {
    final userId = currentUserId ?? 'current_user';
    final newNote = LoveNoteModel(
      id: _uuid.v4(),
      relationshipId: relationshipId,
      senderId: userId,
      title: title,
      content: content,
      unlockAt: unlockAt,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _localNotes.insert(0, newNote);
    if (!_notesController.isClosed) {
      _notesController.add(_localNotes);
    }

    try {
      await _client.from('love_notes').insert(newNote.toJson()).timeout(const Duration(seconds: 8));
    } catch (_) {}

    return newNote;
  }

  /// Mark love note as read
  Future<void> markAsRead(String noteId) async {
    final idx = _localNotes.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      _localNotes[idx] = _localNotes[idx].copyWith(isRead: true);
      if (!_notesController.isClosed) {
        _notesController.add(_localNotes);
      }
    }
    try {
      await _client.from('love_notes').update({'is_read': true}).eq('id', noteId).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
