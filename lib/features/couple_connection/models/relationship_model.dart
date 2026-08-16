import 'package:equatable/equatable.dart';
import '../../auth/models/user_profile.dart';

enum RelationshipStatus { pending, active, paused, disconnected }

class RelationshipModel extends Equatable {
  final String id;
  final String user1Id;
  final String? user2Id;
  final String inviteCode;
  final RelationshipStatus status;
  final DateTime? anniversaryDate;
  final String? customNickname;
  final String themePreference;
  final DateTime createdAt;
  final UserProfile? partnerProfile;

  const RelationshipModel({
    required this.id,
    required this.user1Id,
    this.user2Id,
    required this.inviteCode,
    this.status = RelationshipStatus.pending,
    this.anniversaryDate,
    this.customNickname,
    this.themePreference = 'obsidian_gold',
    required this.createdAt,
    this.partnerProfile,
  });

  bool get isActive => status == RelationshipStatus.active && user2Id != null;

  RelationshipModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? inviteCode,
    RelationshipStatus? status,
    DateTime? anniversaryDate,
    String? customNickname,
    String? themePreference,
    DateTime? createdAt,
    UserProfile? partnerProfile,
  }) {
    return RelationshipModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      customNickname: customNickname ?? this.customNickname,
      themePreference: themePreference ?? this.themePreference,
      createdAt: createdAt ?? this.createdAt,
      partnerProfile: partnerProfile ?? this.partnerProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'invite_code': inviteCode,
      'status': status.name,
      'anniversary_date': anniversaryDate?.toIso8601String().split('T').first,
      'custom_nickname': customNickname,
      'theme_preference': themePreference,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RelationshipModel.fromJson(Map<String, dynamic> json, {UserProfile? partner}) {
    RelationshipStatus parseStatus(String? val) {
      switch (val) {
        case 'active':
          return RelationshipStatus.active;
        case 'paused':
          return RelationshipStatus.paused;
        case 'disconnected':
          return RelationshipStatus.disconnected;
        default:
          return RelationshipStatus.pending;
      }
    }

    return RelationshipModel(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String?,
      inviteCode: json['invite_code'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      anniversaryDate: json['anniversary_date'] != null
          ? DateTime.tryParse(json['anniversary_date'] as String)
          : null,
      customNickname: json['custom_nickname'] as String?,
      themePreference: json['theme_preference'] as String? ?? 'obsidian_gold',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      partnerProfile: partner,
    );
  }

  @override
  List<Object?> get props => [
        id,
        user1Id,
        user2Id,
        inviteCode,
        status,
        anniversaryDate,
        customNickname,
        themePreference,
        createdAt,
        partnerProfile,
      ];
}
