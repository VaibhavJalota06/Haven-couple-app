import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpSubmitted>(_onAuthSignUpSubmitted);
    on<AuthSignInSubmitted>(_onAuthSignInSubmitted);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      try {
        final profile = await _authRepository.getUserProfile(user.id);
        emit(Authenticated(profile));
      } catch (e) {
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final profile = await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      emit(Authenticated(profile));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthSignInSubmitted(
    AuthSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final profile = await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(profile));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordReset(event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is Authenticated) {
      try {
        final updated = await _authRepository.updateProfile(
          fullName: event.fullName,
          nickname: event.nickname,
          avatarUrl: event.avatarUrl,
          coverUrl: event.coverUrl,
          bio: event.bio,
          work: event.work,
          education: event.education,
          currentCity: event.currentCity,
          hometown: event.hometown,
          relationshipStatus: event.relationshipStatus,
          website: event.website,
          hobbies: event.hobbies,
          mood: event.mood,
          moodEmoji: event.moodEmoji,
        );
        emit(Authenticated(updated));
      } catch (e) {
        emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
