import 'dart:io';
import 'package:equatable/equatable.dart';
import '../models/message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStreamStarted extends ChatEvent {
  final String relationshipId;

  const ChatStreamStarted(this.relationshipId);

  @override
  List<Object?> get props => [relationshipId];
}

class ChatMessagesUpdated extends ChatEvent {
  final List<MessageModel> messages;

  const ChatMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatTextMessageSent extends ChatEvent {
  final String relationshipId;
  final String content;
  final String? replyToId;
  final DateTime? scheduledFor;

  const ChatTextMessageSent({
    required this.relationshipId,
    required this.content,
    this.replyToId,
    this.scheduledFor,
  });

  @override
  List<Object?> get props => [relationshipId, content, replyToId, scheduledFor];
}

class ChatMediaMessageSent extends ChatEvent {
  final String relationshipId;
  final File file;
  final MessageType mediaType;
  final int? durationSeconds;
  final String? caption;

  const ChatMediaMessageSent({
    required this.relationshipId,
    required this.file,
    required this.mediaType,
    this.durationSeconds,
    this.caption,
  });

  @override
  List<Object?> get props => [relationshipId, file, mediaType, durationSeconds, caption];
}

class ChatReactionToggled extends ChatEvent {
  final String messageId;
  final String reaction;

  const ChatReactionToggled({required this.messageId, required this.reaction});

  @override
  List<Object?> get props => [messageId, reaction];
}

class ChatPinToggled extends ChatEvent {
  final String messageId;
  final bool currentPinStatus;

  const ChatPinToggled({required this.messageId, required this.currentPinStatus});

  @override
  List<Object?> get props => [messageId, currentPinStatus];
}

class ChatStarToggled extends ChatEvent {
  final String messageId;
  final bool currentStarStatus;

  const ChatStarToggled({required this.messageId, required this.currentStarStatus});

  @override
  List<Object?> get props => [messageId, currentStarStatus];
}

class ChatMessageDeleted extends ChatEvent {
  final String messageId;

  const ChatMessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatMessageUnsent extends ChatEvent {
  final String messageId;

  const ChatMessageUnsent(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatMessagesMarkedAsRead extends ChatEvent {
  final String relationshipId;

  const ChatMessagesMarkedAsRead(this.relationshipId);

  @override
  List<Object?> get props => [relationshipId];
}
