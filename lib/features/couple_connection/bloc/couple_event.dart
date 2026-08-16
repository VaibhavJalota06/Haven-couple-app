import 'package:equatable/equatable.dart';
import '../../auth/models/user_profile.dart';


abstract class CoupleEvent extends Equatable {
  const CoupleEvent();

  @override
  List<Object?> get props => [];
}

class CheckCoupleStatusRequested extends CoupleEvent {}

class CreateRelationshipRequested extends CoupleEvent {}

class JoinRelationshipRequested extends CoupleEvent {
  final String inviteCode;

  const JoinRelationshipRequested(this.inviteCode);

  @override
  List<Object?> get props => [inviteCode];
}

class UpdateRelationshipDetailsRequested extends CoupleEvent {
  final String relationshipId;
  final DateTime? anniversaryDate;
  final String? customNickname;
  final String? themePreference;

  const UpdateRelationshipDetailsRequested({
    required this.relationshipId,
    this.anniversaryDate,
    this.customNickname,
    this.themePreference,
  });

  @override
  List<Object?> get props => [
        relationshipId,
        anniversaryDate,
        customNickname,
        themePreference,
      ];
}

class SetOfficialPartnerRequested extends CoupleEvent {
  final UserProfile partnerProfile;

  const SetOfficialPartnerRequested(this.partnerProfile);

  @override
  List<Object?> get props => [partnerProfile];
}

