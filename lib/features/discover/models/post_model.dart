import 'package:equatable/equatable.dart';

enum PostMediaType { photo, reel }

class PostModel extends Equatable {
  final String id;
  final String userId;
  final String? userFullName;
  final String? userAvatarUrl;
  final String mediaUrl;
  final String? thumbnailUrl;
  final PostMediaType mediaType;
  final String? caption;
  final String? locationName;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.userId,
    this.userFullName,
    this.userAvatarUrl,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.mediaType = PostMediaType.photo,
    this.caption,
    this.locationName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'media_type': mediaType.name,
        'caption': caption,
        'location_name': locationName,
        'created_at': createdAt.toIso8601String(),
      };

  factory PostModel.fromJson(Map<String, dynamic> json, {String? userFullName, String? userAvatarUrl}) {
    final mediaTypeStr = json['media_type'] as String?;
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userFullName: userFullName ?? (json['profiles'] != null ? json['profiles']['full_name'] as String? : null),
      userAvatarUrl: userAvatarUrl ?? (json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null),
      mediaUrl: json['media_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaType: mediaTypeStr == 'reel' ? PostMediaType.reel : PostMediaType.photo,
      caption: json['caption'] as String?,
      locationName: json['location_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, mediaUrl, mediaType, caption, createdAt];
}
