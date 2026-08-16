import 'package:flutter_test/flutter_test.dart';
import 'package:haven/features/chat/models/message_model.dart';

void main() {
  group('MessageModel Tests', () {
    test('Correctly serializes and deserializes text and media messages', () {
      final now = DateTime.now();
      final message = MessageModel(
        id: 'msg_001',
        relationshipId: 'rel_001',
        senderId: 'user_001',
        content: 'I love you to the moon and back!',
        mediaType: MessageType.text,
        isPinned: true,
        isStarred: true,
        createdAt: now,
      );

      final json = message.toJson();
      final parsed = MessageModel.fromJson(json);

      expect(parsed.id, equals('msg_001'));
      expect(parsed.relationshipId, equals('rel_001'));
      expect(parsed.content, equals('I love you to the moon and back!'));
      expect(parsed.isPinned, isTrue);
      expect(parsed.isStarred, isTrue);
    });

    test('Correctly handles reactions serialization', () {
      final reaction = MessageReaction(
        id: 'r_1',
        messageId: 'msg_001',
        userId: 'user_002',
        reaction: '❤️',
        createdAt: DateTime.now(),
      );

      final json = reaction.toJson();
      final parsed = MessageReaction.fromJson(json);

      expect(parsed.id, equals('r_1'));
      expect(parsed.reaction, equals('❤️'));
      expect(parsed.userId, equals('user_002'));
    });

    test('Correctly handles unsend and soft deletion flags', () {
      final message = MessageModel(
        id: 'msg_002',
        relationshipId: 'rel_001',
        senderId: 'user_001',
        content: 'Secret message that will be unsent',
        mediaType: MessageType.text,
        createdAt: DateTime.now(),
      );

      final unsent = message.copyWith(isDeleted: true, content: 'This message was deleted');
      expect(unsent.isDeleted, isTrue);
      expect(unsent.content, equals('This message was deleted'));
    });
  });
}
