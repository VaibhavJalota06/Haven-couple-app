import '../../auth/models/user_profile.dart';

class ConversationThread {
  final String id;
  final UserProfile participant;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isSpecialCouple; // Highlights primary partner with gold heart
  final String? activeNote; // Instagram DM Note (e.g. "Listening to jazz 🎷")

  ConversationThread({
    required this.id,
    required this.participant,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isSpecialCouple = false,
    this.activeNote,
  });
}
