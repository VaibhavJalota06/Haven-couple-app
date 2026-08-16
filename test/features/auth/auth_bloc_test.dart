import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:haven/features/auth/bloc/auth_bloc.dart';
import 'package:haven/features/auth/bloc/auth_event.dart';
import 'package:haven/features/auth/bloc/auth_state.dart';
import 'package:haven/features/auth/models/user_profile.dart';
import 'package:haven/features/auth/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc Unit Tests', () {
    late MockAuthRepository mockAuthRepository;
    final testUser = UserProfile(
      id: 'test_user_1',
      email: 'maya@example.com',
      fullName: 'Maya Chen',
      createdAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    test('Initial state is AuthInitial', () {
      expect(AuthBloc(authRepository: mockAuthRepository).state, equals(AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'Emits [AuthLoading, Authenticated] when sign in succeeds',
      build: () {
        when(() => mockAuthRepository.signInWithEmail(
              email: 'maya@example.com',
              password: 'password123',
            )).thenAnswer((_) async => testUser);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthSignInSubmitted(
        email: 'maya@example.com',
        password: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Emits [AuthLoading, AuthFailure] when sign in fails',
      build: () {
        when(() => mockAuthRepository.signInWithEmail(
              email: 'maya@example.com',
              password: 'wrong_password',
            )).thenThrow(Exception('Invalid login credentials'));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthSignInSubmitted(
        email: 'maya@example.com',
        password: 'wrong_password',
      )),
      expect: () => [
        AuthLoading(),
        const AuthFailure('Invalid login credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Emits [AuthLoading, Unauthenticated] on sign out',
      build: () {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });
}
