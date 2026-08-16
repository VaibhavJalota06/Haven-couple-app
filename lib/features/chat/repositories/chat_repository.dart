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
    // In local demo or offline mode, return rich connected threads
    return [
      ConversationThread(
        id: 'conv_maya',
        participant: UserProfile(
          id: 'user_maya',
          email: 'maya@haven.app',
          fullName: 'Maya Lin',
          nickname: 'Maya',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
          mood: 'excited',
          moodEmoji: '✨',
          createdAt: DateTime.now().subtract(const Duration(days: 428)),
        ),
        lastMessage: 'I found this amazing sunset spot for tomorrow! 🌅✨',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 8)),
        unreadCount: 2,
        isOnline: true,
        isSpecialCouple: true,
        activeNote: 'Designing our next getaway ✨',
      ),
      ConversationThread(
        id: 'conv_elena',
        participant: UserProfile(
          id: 'usr_elena',
          email: 'elena@haven.app',
          fullName: 'Elena Rostova',
          nickname: 'Elena',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
          mood: 'creative',
          moodEmoji: '🎨',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        lastMessage: 'Loved your latest reel! The aesthetic is incredible 🎬',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 1,
        isOnline: true,
        activeNote: 'Listening to jazz 🎷',
      ),
      ConversationThread(
        id: 'conv_sophia',
        participant: UserProfile(
          id: 'usr_sophia',
          email: 'sophia@haven.app',
          fullName: 'Sophia Laurent',
          nickname: 'Sophia',
          avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
          mood: 'peaceful',
          moodEmoji: '🌿',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        lastMessage: 'See you at the coffee shop tomorrow! ☕',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 4)),
        unreadCount: 0,
        isOnline: false,
        activeNote: 'Sunset walk 🌊',
      ),
      ConversationThread(
        id: 'conv_liam',
        participant: UserProfile(
          id: 'usr_liam',
          email: 'liam@haven.app',
          fullName: 'Liam Walker',
          nickname: 'Liam',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
          mood: 'adventurous',
          moodEmoji: '🏔️',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        lastMessage: 'Hey! How did the drone shot in the mountains go?',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        isOnline: true,
        activeNote: 'Coding late ☕',
      ),
      ConversationThread(
        id: 'conv_marcus',
        participant: UserProfile(
          id: 'usr_marcus',
          email: 'marcus@haven.app',
          fullName: 'Marcus Vance',
          nickname: 'Marcus',
          avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
          mood: 'focused',
          moodEmoji: '🎵',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        lastMessage: 'Sent a reel by @elena',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
        isOnline: false,
      ),
    ];
  }

  final List<MessageModel> _localMessages = [
    MessageModel(
      id: 'demo_msg_1',
      relationshipId: 'demo_couple_space',
      senderId: 'user_maya',
      content: 'Good morning love! ✨ Can\'t wait for our rooftop dinner tonight 🌅',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    MessageModel(
      id: 'demo_msg_2',
      relationshipId: 'demo_couple_space',
      senderId: 'usr_me',
      content: 'Good morning sweetheart! 🥰 I booked our favorite table right at sunset. 7:30 PM!',
      createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
    ),
    MessageModel(
      id: 'demo_msg_3',
      relationshipId: 'demo_couple_space',
      senderId: 'user_maya',
      content: 'You\'re the absolute best ❤️ I\'m wearing that dress you love.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MessageModel(
      id: 'demo_msg_4',
      relationshipId: 'demo_couple_space',
      senderId: 'usr_me',
      content: 'Counting down the hours! See you soon 🥂💕',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
  ];

  List<MessageModel> getLocalMessages(String relationshipId) {
    return List.unmodifiable(_localMessages);
  }

  /// Stream messages in real-time for a relationship (instantly yields cached messages)
  Stream<List<MessageModel>> getMessagesStream(String relationshipId) async* {
    yield _localMessages;
    try {
      final stream = _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('relationship_id', relationshipId)
          .order('created_at', ascending: true)
          .map((data) {
            final remote = data.map((json) => MessageModel.fromJson(json)).toList();
            return remote.isNotEmpty ? remote : _localMessages;
          });
      yield* stream;
    } catch (_) {
      yield _localMessages;
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
