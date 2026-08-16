import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/couple_repository.dart';
import 'couple_event.dart';
import 'couple_state.dart';

class CoupleBloc extends Bloc<CoupleEvent, CoupleState> {
  final CoupleRepository _coupleRepository;

  CoupleBloc({required CoupleRepository coupleRepository})
      : _coupleRepository = coupleRepository,
        super(CoupleInitial()) {
    on<CheckCoupleStatusRequested>(_onCheckCoupleStatusRequested);
    on<CreateRelationshipRequested>(_onCreateRelationshipRequested);
    on<JoinRelationshipRequested>(_onJoinRelationshipRequested);
    on<UpdateRelationshipDetailsRequested>(_onUpdateRelationshipDetailsRequested);
    on<SetOfficialPartnerRequested>(_onSetOfficialPartnerRequested);
  }


  Future<void> _onCheckCoupleStatusRequested(
    CheckCoupleStatusRequested event,
    Emitter<CoupleState> emit,
  ) async {
    emit(CoupleLoading());
    try {
      final relationship = await _coupleRepository.getCurrentRelationship();
      if (relationship == null) {
        emit(const CoupleNotPaired());
      } else if (relationship.isActive) {
        emit(CouplePaired(relationship));
      } else {
        emit(CoupleNotPaired(pendingRelationship: relationship));
      }
    } catch (e) {
      emit(CoupleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateRelationshipRequested(
    CreateRelationshipRequested event,
    Emitter<CoupleState> emit,
  ) async {
    emit(CoupleLoading());
    try {
      final relationship = await _coupleRepository.createRelationship();
      emit(CoupleNotPaired(pendingRelationship: relationship));
    } catch (e) {
      emit(CoupleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onJoinRelationshipRequested(
    JoinRelationshipRequested event,
    Emitter<CoupleState> emit,
  ) async {
    emit(CoupleLoading());
    try {
      final relationship = await _coupleRepository.joinRelationshipByCode(event.inviteCode);
      emit(CouplePaired(relationship));
    } catch (e) {
      emit(CoupleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateRelationshipDetailsRequested(
    UpdateRelationshipDetailsRequested event,
    Emitter<CoupleState> emit,
  ) async {
    try {
      final updated = await _coupleRepository.updateRelationship(
        relationshipId: event.relationshipId,
        anniversaryDate: event.anniversaryDate,
        customNickname: event.customNickname,
        themePreference: event.themePreference,
      );
      emit(CouplePaired(updated));
    } catch (e) {
      emit(CoupleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSetOfficialPartnerRequested(
    SetOfficialPartnerRequested event,
    Emitter<CoupleState> emit,
  ) async {
    emit(CoupleLoading());
    try {
      final updated = await _coupleRepository.setOfficialPartner(event.partnerProfile);
      emit(CouplePaired(updated));
    } catch (e) {
      emit(CoupleError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

