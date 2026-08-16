import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignUpSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const AuthSignUpSubmitted({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthSignInSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? fullName;
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
  final List<String>? hobbies;
  final String? mood;
  final String? moodEmoji;

  const AuthProfileUpdateRequested({
    this.fullName,
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
    this.hobbies,
    this.mood,
    this.moodEmoji,
  });

  @override
  List<Object?> get props => [
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
      ];
}

class AuthAccountDeactivateRequested extends AuthEvent {}

class AuthAccountDeleteRequested extends AuthEvent {}
