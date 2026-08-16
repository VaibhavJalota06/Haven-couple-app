import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messagesSubscription;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<ChatStreamStarted>(_onChatStreamStarted);
    on<ChatMessagesUpdated>(_onChatMessagesUpdated);
    on<ChatTextMessageSent>(_onChatTextMessageSent);
    on<ChatMediaMessageSent>(_onChatMediaMessageSent);
    on<ChatReactionToggled>(_onChatReactionToggled);
    on<ChatPinToggled>(_onChatPinToggled);
    on<ChatStarToggled>(_onChatStarToggled);
    on<ChatMessageDeleted>(_onChatMessageDeleted);
    on<ChatMessageUnsent>(_onChatMessageUnsent);
    on<ChatMessagesMarkedAsRead>(_onChatMessagesMarkedAsRead);
  }

  Future<void> _onChatStreamStarted(
    ChatStreamStarted event,
    Emitter<ChatState> emit,
  ) async {
    final cached = _chatRepository.getLocalMessages(event.relationshipId);
    if (cached.isNotEmpty) {
      emit(ChatLoaded(messages: cached));
    } else {
      emit(ChatLoading());
    }
    await _messagesSubscription?.cancel();

    _messagesSubscription = _chatRepository
        .getMessagesStream(event.relationshipId)
        .listen(
      (messages) {
        add(ChatMessagesUpdated(messages));
      },
      onError: (err) {
        final cached = _chatRepository.getLocalMessages(event.relationshipId);
        add(ChatMessagesUpdated(cached));
      },
      cancelOnError: false,
    );
  }

  void _onChatMessagesUpdated(
    ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final current = state as ChatLoaded;
      emit(current.copyWith(messages: event.messages));
    } else {
      emit(ChatLoaded(messages: event.messages));
    }
  }

  Future<void> _onChatTextMessageSent(
    ChatTextMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final newMsg = await _chatRepository.sendTextMessage(
        relationshipId: event.relationshipId,
        content: event.content,
        replyToId: event.replyToId,
        scheduledFor: event.scheduledFor,
      );
      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        if (!currentMessages.any((m) => m.id == newMsg.id)) {
          emit((state as ChatLoaded).copyWith(messages: [...currentMessages, newMsg]));
        }
      } else {
        emit(ChatLoaded(messages: [newMsg]));
      }
    } catch (_) {}
  }

  Future<void> _onChatMediaMessageSent(
    ChatMediaMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isSendingMedia: true));
    }
    try {
      final newMsg = await _chatRepository.sendMediaMessage(
        relationshipId: event.relationshipId,
        file: event.file,
        mediaType: event.mediaType,
        durationSeconds: event.durationSeconds,
        caption: event.caption,
      );
      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        if (!currentMessages.any((m) => m.id == newMsg.id)) {
          emit((state as ChatLoaded).copyWith(
            messages: [...currentMessages, newMsg],
            isSendingMedia: false,
          ));
        }
      }
    } catch (e) {
      emit(ChatError(e.toString().replaceAll('Exception: ', '')));
    } finally {
      if (state is ChatLoaded && (state as ChatLoaded).isSendingMedia) {
        emit((state as ChatLoaded).copyWith(isSendingMedia: false));
      }
    }
  }

  Future<void> _onChatReactionToggled(
    ChatReactionToggled event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.toggleReaction(
        messageId: event.messageId,
        reaction: event.reaction,
      );
      if (state is ChatLoaded) {
        final updatedList = _chatRepository.getLocalMessages('');
        emit((state as ChatLoaded).copyWith(messages: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onChatPinToggled(
    ChatPinToggled event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.togglePinMessage(event.messageId, event.currentPinStatus);
      if (state is ChatLoaded) {
        final updatedList = _chatRepository.getLocalMessages('');
        emit((state as ChatLoaded).copyWith(messages: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onChatStarToggled(
    ChatStarToggled event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.toggleStarMessage(event.messageId, event.currentStarStatus);
      if (state is ChatLoaded) {
        final updatedList = _chatRepository.getLocalMessages('');
        emit((state as ChatLoaded).copyWith(messages: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onChatMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);
      if (state is ChatLoaded) {
        final updatedList = _chatRepository.getLocalMessages('');
        emit((state as ChatLoaded).copyWith(messages: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onChatMessageUnsent(
    ChatMessageUnsent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.unsendMessage(event.messageId);
      if (state is ChatLoaded) {
        final updatedList = _chatRepository.getLocalMessages('');
        emit((state as ChatLoaded).copyWith(messages: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onChatMessagesMarkedAsRead(
    ChatMessagesMarkedAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.markMessagesAsRead(event.relationshipId);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
