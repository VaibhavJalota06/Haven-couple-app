import 'package:flutter_test/flutter_test.dart';
import 'package:haven/features/plans/models/plan_models.dart';
import 'package:haven/features/plans/repositories/plans_repository.dart';

void main() {
  group('Plans Feature Tests', () {
    late PlansRepository repository;

    setUp(() {
      repository = PlansRepository();
    });

    test('DatePlanModel serialization and state copy', () {
      final date = DateTime.now();
      final plan = DatePlanModel(
        id: 'dp_101',
        relationshipId: 'rel_test',
        createdBy: 'usr_1',
        title: 'Sunset Beach Picnic 🌅',
        description: 'Fresh fruit and wine',
        scheduledFor: date,
        budget: 75.0,
        createdAt: date,
      );

      final json = plan.toJson();
      expect(json['title'], 'Sunset Beach Picnic 🌅');
      expect(json['budget'], 75.0);

      final copy = plan.copyWith(isCompleted: true);
      expect(copy.isCompleted, true);
      expect(copy.title, 'Sunset Beach Picnic 🌅');
    });

    test('BucketListItemModel serialization and toggle completion', () {
      final item = BucketListItemModel(
        id: 'bk_1',
        relationshipId: 'rel_test',
        createdBy: 'usr_1',
        title: 'Learn Scuba Diving together 🤿',
        category: 'Adventure',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      expect(item.isCompleted, false);
      final completed = item.copyWith(isCompleted: true);
      expect(completed.isCompleted, true);
    });

    test('SharedGoalModel progress calculation and contributions', () {
      final goal = SharedGoalModel(
        id: 'sg_1',
        relationshipId: 'rel_test',
        createdBy: 'usr_1',
        title: 'New Living Room Velvet Sofa',
        category: 'Home',
        targetAmount: 1000.0,
        currentAmount: 250.0,
        currency: 'USD',
        createdAt: DateTime.now(),
      );

      expect(goal.progressPercentage, 0.25);
      expect(goal.isCompleted, false);

      final funded = goal.copyWith(currentAmount: 1000.0, isCompleted: true);
      expect(funded.progressPercentage, 1.0);
      expect(funded.isCompleted, true);
    });

    test('PlansRepository creates and queries date plans locally and reactively', () async {
      final plan = await repository.createDatePlan(
        relationshipId: 'rel_test_local',
        title: 'Michelin Star Anniversary Dinner',
        scheduledFor: DateTime.now().add(const Duration(days: 5)),
        budget: 300.0,
      );

      expect(plan.title, 'Michelin Star Anniversary Dinner');
      final plans = repository.getDatePlans('rel_test_local');
      expect(plans.any((p) => p.id == plan.id), true);
    });
  });
}
