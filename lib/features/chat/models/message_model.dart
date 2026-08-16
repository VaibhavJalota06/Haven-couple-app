import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, voice, document, location, gameInvite }
enum ReceiptStatus { sent, delivered, read }

class MessageReaction extends Equatable {
  final String id;
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) => MessageReaction(
        id: json['id'] as String,
        messageId: json['message_id'] as String,
        userId: json['user_id'] as String,
        reaction: json['reaction'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'user_id': userId,
        'reaction': reaction,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, messageId, userId, reaction, createdAt];
}

class MessageModel extends Equatable {
  final String id;
  final String relationshipId;
  final String senderId;
  final String? content;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final MessageType mediaType;
  final int? mediaDurationSeconds;
  final String? replyToId;
  final MessageModel? replyToMessage;
  final bool isViewOnce;
  final DateTime? viewedAt;
  final bool isPinned;
  final bool isStarred;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime? scheduledFor;
  final ReceiptStatus receiptStatus;
  final List<MessageReaction> reactions;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.relationshipId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaType = MessageType.text,
    this.mediaDurationSeconds,
    this.replyToId,
    this.replyToMessage,
    this.isViewOnce = false,
    this.viewedAt,
    this.isPinned = false,
    this.isStarred = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.scheduledFor,
    this.receiptStatus = ReceiptStatus.sent,
    this.reactions = const [],
    required this.createdAt,
  });

  bool get isSenderCurrentUser => false; // Resolved in UI using AuthBloc/currentUserId

  MessageModel copyWith({
    String? id,
    String? relationshipId,
    String? senderId,
    String? content,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    MessageType? mediaType,
    int? mediaDurationSeconds,
    String? replyToId,
    MessageModel? replyToMessage,
    bool? isViewOnce,
    DateTime? viewedAt,
    bool? isPinned,
    bool? isStarred,
    bool? isDeleted,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? scheduledFor,
    ReceiptStatus? receiptStatus,
    List<MessageReaction>? reactions,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      mediaDurationSeconds: mediaDurationSeconds ?? this.mediaDurationSeconds,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isViewOnce: isViewOnce ?? this.isViewOnce,
      viewedAt: viewedAt ?? this.viewedAt,
      isPinned: isPinned ?? this.isPinned,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      receiptStatus: receiptStatus ?? this.receiptStatus,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'media_thumbnail_url': mediaThumbnailUrl,
      'media_type': mediaType.name,
      'media_duration_seconds': mediaDurationSeconds,
      'reply_to_id': replyToId,
      'is_view_once': isViewOnce,
      'viewed_at': viewedAt?.toIso8601String(),
      'is_pinned': isPinned,
      'is_starred': isStarred,
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json, {List<MessageReaction> reactions = const []}) {
    MessageType parseMediaType(String? val) {
      switch (val) {
        case 'image':
          return MessageType.image;
        case 'video':
          return MessageType.video;
        case 'voice':
          return MessageType.voice;
        case 'document':
          return MessageType.document;
        case 'location':
          return MessageType.location;
        case 'game_invite':
          return MessageType.gameInvite;
        default:
          return MessageType.text;
      }
    }

    return MessageModel(
      id: json['id'] as String,
      relationshipId: json['relationship_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      mediaType: parseMediaType(json['media_type'] as String?),
      mediaDurationSeconds: json['media_duration_seconds'] as int?,
      replyToId: json['reply_to_id'] as String?,
      isViewOnce: json['is_view_once'] as bool? ?? false,
      viewedAt: json['viewed_at'] != null ? DateTime.tryParse(json['viewed_at'] as String) : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      isStarred: json['is_starred'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null ? DateTime.tryParse(json['edited_at'] as String) : null,
      scheduledFor: json['scheduled_for'] != null ? DateTime.tryParse(json['scheduled_for'] as String) : null,
      receiptStatus: ReceiptStatus.read, // default resolved from message_receipts
      reactions: reactions,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        senderId,
        content,
        mediaUrl,
        mediaType,
        replyToId,
        isPinned,
        isStarred,
        isDeleted,
        isEdited,
        receiptStatus,
        reactions,
        createdAt,
      ];
}
