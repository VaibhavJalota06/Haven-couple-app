import 'package:flutter_test/flutter_test.dart';
import 'package:haven/features/together/models/love_note_model.dart';
import 'package:haven/features/together/repositories/love_notes_repository.dart';

void main() {
  group('LoveNotes & Time Capsules Feature Tests', () {
    test('LoveNoteModel serialization and unlock calculations', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final future = DateTime.now().add(const Duration(days: 10));

      final unlockedNote = LoveNoteModel(
        id: 'note_1',
        relationshipId: 'rel_1',
        senderId: 'user_1',
        title: 'Happy Anniversary!',
        content: 'I love you so much!',
        unlockAt: past,
        createdAt: DateTime.now(),
      );

      final lockedNote = LoveNoteModel(
        id: 'note_2',
        relationshipId: 'rel_1',
        senderId: 'user_1',
        title: 'Open in 2027',
        content: 'Secret message',
        unlockAt: future,
        createdAt: DateTime.now(),
      );

      expect(unlockedNote.isUnlocked, isTrue);
      expect(lockedNote.isUnlocked, isFalse);

      final json = unlockedNote.toJson();
      final parsed = LoveNoteModel.fromJson(json);
      expect(parsed.id, equals('note_1'));
      expect(parsed.title, equals('Happy Anniversary!'));
    });

    test('LoveNotesRepository creates and streams love notes', () async {
      final repo = LoveNotesRepository();
      final unlockAt = DateTime.now().add(const Duration(days: 5));

      final note = await repo.createLoveNote(
        relationshipId: 'rel_test',
        title: 'Surprise Letter',
        content: 'Looking forward to our trip!',
        unlockAt: unlockAt,
      );

      expect(note.title, equals('Surprise Letter'));
      expect(note.relationshipId, equals('rel_test'));

      final localNotes = repo.getLocalLoveNotes('rel_test');
      expect(localNotes.isNotEmpty, isTrue);
      expect(localNotes.first.id, equals(note.id));

      await repo.markAsRead(note.id);
      expect(repo.getLocalLoveNotes('rel_test').first.isRead, isTrue);
    });
  });
}
