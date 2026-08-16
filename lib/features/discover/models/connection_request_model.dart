import 'package:equatable/equatable.dart';
import '../../auth/models/user_profile.dart';

enum ConnectionRequestStatus { none, pending, accepted, declined, cancelled }

class ConnectionRequestModel extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final ConnectionRequestStatus status;
  final String? message;
  final DateTime createdAt;
  final UserProfile? senderProfile;
  final UserProfile? receiverProfile;

  const ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = ConnectionRequestStatus.pending,
    this.message,
    required this.createdAt,
    this.senderProfile,
    this.receiverProfile,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': status.name,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json, {UserProfile? sender, UserProfile? receiver}) {
    ConnectionRequestStatus parseStatus(String? val) {
      switch (val) {
        case 'accepted':
          return ConnectionRequestStatus.accepted;
        case 'declined':
          return ConnectionRequestStatus.declined;
        case 'cancelled':
          return ConnectionRequestStatus.cancelled;
        default:
          return ConnectionRequestStatus.pending;
      }
    }

    return ConnectionRequestModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: parseStatus(json['status'] as String?),
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      senderProfile: sender,
      receiverProfile: receiver,
    );
  }

  @override
  List<Object?> get props => [id, senderId, receiverId, status, message, createdAt];
}
