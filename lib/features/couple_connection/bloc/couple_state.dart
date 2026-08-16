import 'package:equatable/equatable.dart';
import '../models/relationship_model.dart';

abstract class CoupleState extends Equatable {
  const CoupleState();

  @override
  List<Object?> get props => [];
}

class CoupleInitial extends CoupleState {}

class CoupleLoading extends CoupleState {}

class CoupleNotPaired extends CoupleState {
  final RelationshipModel? pendingRelationship;

  const CoupleNotPaired({this.pendingRelationship});

  @override
  List<Object?> get props => [pendingRelationship];
}

class CouplePaired extends CoupleState {
  final RelationshipModel relationship;

  const CouplePaired(this.relationship);

  @override
  List<Object?> get props => [relationship];
}

class CoupleError extends CoupleState {
  final String message;

  const CoupleError(this.message);

  @override
  List<Object?> get props => [message];
}
