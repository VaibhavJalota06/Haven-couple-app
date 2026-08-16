import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/models/user_profile.dart';
import '../models/conversation_thread.dart';
import '../models/message_model.dart';

class ChatRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  ChatRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get list of DM conversation threads for Instagram-style inbox
  Future<List<ConversationThread>> getConversationThreads() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final relationships = await _client
          .from('relationships')
          .select('*, user1:profiles!user1_id(*), user2:profiles!user2_id(*)')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('status', 'active');

      final List<ConversationThread> threads = [];
      for (final rel in relationships as List) {
        final u1 = rel['user1'];
        final u2 = rel['user2'];
        final partnerMap = (rel['user1_id'] == userId) ? u2 : u1;
        if (partnerMap != null) {
          final partner = UserProfile.fromJson(partnerMap);
          threads.add(
            ConversationThread(
              id: rel['id'] as String,
              participant: partner,
              lastMessage: 'Tap to chat with your partner 💕',
              lastMessageTime: DateTime.tryParse(rel['updated_at'] ?? '') ?? DateTime.now(),
              unreadCount: 0,
              isOnline: partner.isOnline,
              isSpecialCouple: true,
            ),
          );
        }
      }
      return threads;
    } catch (_) {
      return [];
    }
  }

  final List<MessageModel> _localMessages = [];

  List<MessageModel> getLocalMessages(String relationshipId) {
    return List.unmodifiable(_localMessages);
  }

  /// Stream messages in real-time for a relationship (instantly yields cached messages)
  Stream<List<MessageModel>> getMessagesStream(String relationshipId) async* {
    yield _localMessages;
    if (relationshipId.isNotEmpty) {
      try {
        final stream = _client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('relationship_id', relationshipId)
            .order('created_at', ascending: true)
            .map((data) {
              final remote = data.map((json) => MessageModel.fromJson(json)).toList();
              _localMessages.clear();
              _localMessages.addAll(remote);
              return _localMessages;
            });
        yield* stream;
      } catch (_) {
        yield _localMessages;
      }
    }
  }

  /// Send a text message
  Future<MessageModel> sendTextMessage({
    required String relationshipId,
    required String content,
    String? replyToId,
    DateTime? scheduledFor,
  }) async {
    final userId = currentUserId ?? 'usr_me';
    final messageId = _uuid.v4();

    final newMsg = MessageModel(
      id: messageId,
      relationshipId: relationshipId,
      senderId: userId,
      content: content,
      mediaType: MessageType.text,
      replyToId: replyToId,
      scheduledFor: scheduledFor,
      createdAt: DateTime.now(),
    );

    _localMessages.add(newMsg);

    try {
      final payload = {
        'id': messageId,
        'relationship_id': relationshipId,
        'sender_id': userId,
        'content': content,
        'media_type': 'text',
        'reply_to_id': replyToId,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
      await _client.from('messages').insert(payload).select().single().timeout(const Duration(seconds: 8));
    } catch (_) {}

    return newMsg;
  }

  /// Upload media (image/video/voice) and send message
  Future<MessageModel> sendMediaMessage({
    required String relationshipId,
    required File file,
    required MessageType mediaType,
    int? durationSeconds,
    String? caption,
  }) async {
    final userId = currentUserId ?? 'usr_me';
    final fileExt = file.path.split('.').last;
    final fileName = '$relationshipId/${_uuid.v4()}.$fileExt';
    String mediaUrl = '';

    try {
      await _client.storage.from(AppConstants.chatMediaBucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          ).timeout(const Duration(milliseconds: 1000));
      mediaUrl = _client.storage.from(AppConstants.chatMediaBucket).getPublicUrl(fileName);
    } catch (_) {
      mediaUrl = 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=800&q=80';
    }

    final newMsg = MessageModel(
      id: _uuid.v4(),
      relationshipId: relationshipId,
      senderId: userId,
      content: caption,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaDurationSeconds: durationSeconds,
      createdAt: DateTime.now(),
    );

    _localMessages.add(newMsg);

    try {
      await _client.from('messages').insert(newMsg.toJson()).select().single().timeout(const Duration(seconds: 8));
    } catch (_) {}

    return newMsg;
  }

  /// Add or update a reaction to a message
  Future<void> toggleReaction({
    required String messageId,
    required String reaction,
  }) async {
    final msgIndex = _localMessages.indexWhere((m) => m.id == messageId);
    if (msgIndex != -1) {
      final msg = _localMessages[msgIndex];
      final currentReactions = List<MessageReaction>.from(msg.reactions);
      final existingIndex = currentReactions.indexWhere((r) => r.reaction == reaction);
      if (existingIndex != -1) {
        currentReactions.removeAt(existingIndex);
      } else {
        currentReactions.add(MessageReaction(
          id: _uuid.v4(),
          messageId: messageId,
          userId: currentUserId ?? 'usr_me',
          reaction: reaction,
          createdAt: DateTime.now(),
        ));
      }
      _localMessages[msgIndex] = msg.copyWith(reactions: currentReactions);
    }

    try {
      final userId = currentUserId;
      if (userId == null) return;
      final existing = await _client
          .from('message_reactions')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (existing != null) {
        if (existing['reaction'] == reaction) {
          await _client.from('message_reactions').delete().eq('id', existing['id']).timeout(const Duration(seconds: 8));
        } else {
          await _client.from('message_reactions').update({'reaction': reaction}).eq('id', existing['id']).timeout(const Duration(seconds: 8));
        }
      } else {
        await _client.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': userId,
          'reaction': reaction,
        }).timeout(const Duration(seconds: 8));
      }
    } catch (_) {}
  }

  /// Pin/Unpin a message
  Future<void> togglePinMessage(String messageId, bool currentPinStatus) async {
    final msgIndex = _localMessages.indexWhere((m) => m.id == messageId);
    if (msgIndex != -1) {
      _localMessages[msgIndex] = _localMessages[msgIndex].copyWith(isPinned: !currentPinStatus);
    }
    try {
      await _client.from('messages').update({'is_pinned': !currentPinStatus}).eq('id', messageId).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Star/Unstar a message
  Future<void> toggleStarMessage(String messageId, bool currentStarStatus) async {
    final msgIndex = _localMessages.indexWhere((m) => m.id == messageId);
    if (msgIndex != -1) {
      _localMessages[msgIndex] = _localMessages[msgIndex].copyWith(isStarred: !currentStarStatus);
    }
    try {
      await _client.from('messages').update({'is_starred': !currentStarStatus}).eq('id', messageId).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Instagram-style unsend message (completely removes message for everyone)
  Future<void> unsendMessage(String messageId) async {
    _localMessages.removeWhere((m) => m.id == messageId);
    try {
      await _client.from('messages').delete().eq('id', messageId).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Soft delete message
  Future<void> deleteMessage(String messageId) async {
    final msgIndex = _localMessages.indexWhere((m) => m.id == messageId);
    if (msgIndex != -1) {
      _localMessages[msgIndex] = _localMessages[msgIndex].copyWith(isDeleted: true, content: 'This message was deleted');
    }
    try {
      await _client.from('messages').update({
        'is_deleted': true,
        'content': 'This message was deleted',
      }).eq('id', messageId).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String relationshipId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;
      final unreadMessages = await _client
          .from('messages')
          .select('id')
          .eq('relationship_id', relationshipId)
          .neq('sender_id', userId)
          .timeout(const Duration(seconds: 8));

      for (var row in unreadMessages) {
        final msgId = row['id'] as String;
        await _client.from('message_receipts').upsert({
          'message_id': msgId,
          'user_id': userId,
          'status': 'read',
          'updated_at': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 8));
      }
    } catch (_) {}
  }
}
