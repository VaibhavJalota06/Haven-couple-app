import 'package:equatable/equatable.dart';
import '../models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  final MessageModel? replyingTo;
  final bool isSendingMedia;

  const ChatLoaded({
    required this.messages,
    this.replyingTo,
    this.isSendingMedia = false,
  });

  List<MessageModel> get pinnedMessages =>
      messages.where((m) => m.isPinned && !m.isDeleted).toList();

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    MessageModel? replyingTo,
    bool? clearReplyingTo,
    bool? isSendingMedia,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      replyingTo: clearReplyingTo == true ? null : (replyingTo ?? this.replyingTo),
      isSendingMedia: isSendingMedia ?? this.isSendingMedia,
    );
  }

  @override
  List<Object?> get props => [messages, replyingTo, isSendingMedia];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
