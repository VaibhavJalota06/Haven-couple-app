import 'package:equatable/equatable.dart';

class MemoryModel extends Equatable {
  final String id;
  final String relationshipId;
  final String authorId;
  final String title;
  final String? description;
  final DateTime memoryDate;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final List<String> mediaUrls;
  final String? audioMemoUrl;
  final String category;
  final bool isFavorite;
  final DateTime createdAt;

  const MemoryModel({
    required this.id,
    required this.relationshipId,
    required this.authorId,
    required this.title,
    this.description,
    required this.memoryDate,
    this.locationName,
    this.latitude,
    this.longitude,
    this.mediaUrls = const [],
    this.audioMemoUrl,
    this.category = 'general',
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationship_id': relationshipId,
        'author_id': authorId,
        'title': title,
        'description': description,
        'memory_date': memoryDate.toIso8601String().split('T').first,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'media_urls': mediaUrls,
        'audio_memo_url': audioMemoUrl,
        'category': category,
        'is_favorite': isFavorite,
        'created_at': createdAt.toIso8601String(),
      };

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String,
      relationshipId: json['relationship_id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String? ?? 'Our Memory',
      description: json['description'] as String?,
      memoryDate: json['memory_date'] != null
          ? DateTime.parse(json['memory_date'] as String)
          : DateTime.now(),
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mediaUrls: (json['media_urls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      audioMemoUrl: json['audio_memo_url'] as String?,
      category: json['category'] as String? ?? 'general',
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  MemoryModel copyWith({
    String? id,
    String? relationshipId,
    String? authorId,
    String? title,
    String? description,
    DateTime? memoryDate,
    String? locationName,
    double? latitude,
    double? longitude,
    List<String>? mediaUrls,
    String? audioMemoUrl,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      description: description ?? this.description,
      memoryDate: memoryDate ?? this.memoryDate,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      audioMemoUrl: audioMemoUrl ?? this.audioMemoUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        authorId,
        title,
        description,
        memoryDate,
        mediaUrls,
        category,
        isFavorite,
      ];
}
