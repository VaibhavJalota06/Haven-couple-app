import 'package:equatable/equatable.dart';

enum VaultItemType { photo, video, note, voiceMemo, document }

class VaultItemModel extends Equatable {
  final String id;
  final String relationshipId;
  final String ownerId;
  final VaultItemType itemType;
  final String title;
  final String encryptedPayload; // AES-256-GCM ciphertext
  final String iv;
  final String authTag;
  final String? mediaUrl;
  final int? fileSizeBytes;
  final DateTime createdAt;

  const VaultItemModel({
    required this.id,
    required this.relationshipId,
    required this.ownerId,
    required this.itemType,
    required this.title,
    required this.encryptedPayload,
    required this.iv,
    required this.authTag,
    this.mediaUrl,
    this.fileSizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationship_id': relationshipId,
        'owner_id': ownerId,
        'item_type': itemType.name,
        'title': title,
        'encrypted_payload': encryptedPayload,
        'iv': iv,
        'auth_tag': authTag,
        'media_url': mediaUrl,
        'file_size_bytes': fileSizeBytes,
        'created_at': createdAt.toIso8601String(),
      };

  factory VaultItemModel.fromJson(Map<String, dynamic> json) {
    VaultItemType parseType(String? val) {
      switch (val) {
        case 'video':
          return VaultItemType.video;
        case 'note':
          return VaultItemType.note;
        case 'voiceMemo':
        case 'voice_memo':
          return VaultItemType.voiceMemo;
        case 'document':
          return VaultItemType.document;
        default:
          return VaultItemType.photo;
      }
    }

    return VaultItemModel(
      id: json['id'] as String,
      relationshipId: json['relationship_id'] as String,
      ownerId: json['owner_id'] as String,
      itemType: parseType(json['item_type'] as String?),
      title: json['title'] as String? ?? 'Encrypted Item',
      encryptedPayload: json['encrypted_payload'] as String? ?? '',
      iv: json['iv'] as String? ?? '',
      authTag: json['auth_tag'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        ownerId,
        itemType,
        title,
        encryptedPayload,
        iv,
        authTag,
        mediaUrl,
        createdAt,
      ];
}
