import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:haven/features/couple_connection/bloc/couple_bloc.dart';
import 'package:haven/features/couple_connection/bloc/couple_event.dart';
import 'package:haven/features/couple_connection/bloc/couple_state.dart';
import 'package:haven/features/couple_connection/models/relationship_model.dart';
import 'package:haven/features/couple_connection/repositories/couple_repository.dart';

class MockCoupleRepository extends Mock implements CoupleRepository {}

void main() {
  group('CoupleConnection Unit Tests', () {
    late MockCoupleRepository mockCoupleRepository;

    final activeRelationship = RelationshipModel(
      id: 'rel_123',
      user1Id: 'user_1',
      user2Id: 'user_2',
      inviteCode: '7K2M9X',
      status: RelationshipStatus.active,
      createdAt: DateTime(2024, 1, 1),
    );

    final pendingRelationship = RelationshipModel(
      id: 'rel_456',
      user1Id: 'user_1',
      user2Id: null,
      inviteCode: '8Y3P1Z',
      status: RelationshipStatus.pending,
      createdAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      mockCoupleRepository = MockCoupleRepository();
    });

    test('Initial state is CoupleInitial', () {
      expect(CoupleBloc(coupleRepository: mockCoupleRepository).state, equals(CoupleInitial()));
    });

    blocTest<CoupleBloc, CoupleState>(
      'Emits [CoupleLoading, CouplePaired] when active relationship exists',
      build: () {
        when(() => mockCoupleRepository.getCurrentRelationship())
            .thenAnswer((_) async => activeRelationship);
        return CoupleBloc(coupleRepository: mockCoupleRepository);
      },
      act: (bloc) => bloc.add(CheckCoupleStatusRequested()),
      expect: () => [
        CoupleLoading(),
        CouplePaired(activeRelationship),
      ],
    );

    blocTest<CoupleBloc, CoupleState>(
      'Emits [CoupleLoading, CoupleNotPaired] with pending relationship when invite is awaiting partner',
      build: () {
        when(() => mockCoupleRepository.getCurrentRelationship())
            .thenAnswer((_) async => pendingRelationship);
        return CoupleBloc(coupleRepository: mockCoupleRepository);
      },
      act: (bloc) => bloc.add(CheckCoupleStatusRequested()),
      expect: () => [
        CoupleLoading(),
        CoupleNotPaired(pendingRelationship: pendingRelationship),
      ],
    );

    blocTest<CoupleBloc, CoupleState>(
      'Emits [CoupleLoading, CouplePaired] when successfully joining via code',
      build: () {
        when(() => mockCoupleRepository.joinRelationshipByCode('8Y3P1Z'))
            .thenAnswer((_) async => activeRelationship);
        return CoupleBloc(coupleRepository: mockCoupleRepository);
      },
      act: (bloc) => bloc.add(const JoinRelationshipRequested('8Y3P1Z')),
      expect: () => [
        CoupleLoading(),
        CouplePaired(activeRelationship),
      ],
    );
  });
}
