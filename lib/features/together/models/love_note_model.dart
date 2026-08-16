import 'package:equatable/equatable.dart';

class LoveNoteModel extends Equatable {
  final String id;
  final String relationshipId;
  final String senderId;
  final String title;
  final String content;
  final DateTime unlockAt;
  final bool isRead;
  final DateTime createdAt;

  const LoveNoteModel({
    required this.id,
    required this.relationshipId,
    required this.senderId,
    required this.title,
    required this.content,
    required this.unlockAt,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isUnlocked => DateTime.now().isAfter(unlockAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationship_id': relationshipId,
        'sender_id': senderId,
        'title': title,
        'content': content,
        'unlock_at': unlockAt.toIso8601String(),
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory LoveNoteModel.fromJson(Map<String, dynamic> json) => LoveNoteModel(
        id: json['id'] as String,
        relationshipId: json['relationship_id'] as String,
        senderId: json['sender_id'] as String,
        title: json['title'] as String? ?? 'Time Capsule Letter',
        content: json['content'] as String? ?? '',
        unlockAt: json['unlock_at'] != null
            ? DateTime.parse(json['unlock_at'] as String)
            : DateTime.now(),
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  LoveNoteModel copyWith({
    String? id,
    String? relationshipId,
    String? senderId,
    String? title,
    String? content,
    DateTime? unlockAt,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return LoveNoteModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      content: content ?? this.content,
      unlockAt: unlockAt ?? this.unlockAt,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, relationshipId, senderId, title, unlockAt, isRead];
}
