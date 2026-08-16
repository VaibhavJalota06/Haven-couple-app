import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? nickname;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? work;
  final String? education;
  final String? currentCity;
  final String? hometown;
  final String? relationshipStatus;
  final String? website;
  final List<String> hobbies;
  final String mood;
  final String moodEmoji;
  final DateTime? moodUpdatedAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.nickname,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.work,
    this.education,
    this.currentCity,
    this.hometown,
    this.relationshipStatus,
    this.website,
    this.hobbies = const ['Photography 📷', 'Travel ✈️', 'Cooking 🍳', 'Coffee ☕', 'Indie Music 🎧'],
    this.mood = 'loved',
    this.moodEmoji = '🥰',
    this.moodUpdatedAt,
    this.lastSeen,
    this.isOnline = false,
    required this.createdAt,
  });

  String get displayName => (nickname != null && nickname!.isNotEmpty) ? nickname! : fullName;

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? nickname,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? work,
    String? education,
    String? currentCity,
    String? hometown,
    String? relationshipStatus,
    String? website,
    List<String>? hobbies,
    String? mood,
    String? moodEmoji,
    DateTime? moodUpdatedAt,
    DateTime? lastSeen,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      work: work ?? this.work,
      education: education ?? this.education,
      currentCity: currentCity ?? this.currentCity,
      hometown: hometown ?? this.hometown,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      website: website ?? this.website,
      hobbies: hobbies ?? this.hobbies,
      mood: mood ?? this.mood,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      moodUpdatedAt: moodUpdatedAt ?? this.moodUpdatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'work': work,
      'education': education,
      'current_city': currentCity,
      'hometown': hometown,
      'relationship_status': relationshipStatus,
      'website': website,
      'hobbies': hobbies,
      'mood': mood,
      'mood_emoji': moodEmoji,
      'mood_updated_at': moodUpdatedAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'is_online': isOnline,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Partner',
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      bio: json['bio'] as String?,
      work: json['work'] as String?,
      education: json['education'] as String?,
      currentCity: json['current_city'] as String?,
      hometown: json['hometown'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      website: json['website'] as String?,
      hobbies: json['hobbies'] != null
          ? List<String>.from(json['hobbies'] as List)
          : const ['Photography 📷', 'Travel ✈️', 'Cooking 🍳', 'Coffee ☕', 'Indie Music 🎧'],
      mood: json['mood'] as String? ?? 'loved',
      moodEmoji: json['mood_emoji'] as String? ?? '🥰',
      moodUpdatedAt: json['mood_updated_at'] != null ? DateTime.tryParse(json['mood_updated_at'] as String) : null,
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'] as String) : null,
      isOnline: json['is_online'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        nickname,
        avatarUrl,
        coverUrl,
        bio,
        work,
        education,
        currentCity,
        hometown,
        relationshipStatus,
        website,
        hobbies,
        mood,
        moodEmoji,
        moodUpdatedAt,
        lastSeen,
        isOnline,
        createdAt,
      ];
}
