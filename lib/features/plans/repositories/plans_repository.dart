import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../models/plan_models.dart';

class PlansRepository {
  static final PlansRepository _instance = PlansRepository._internal();
  factory PlansRepository({SupabaseClient? client}) {
    if (client != null) {
      _instance._client = client;
    }
    return _instance;
  }

  PlansRepository._internal() {
    _initLocalData();
  }

  SupabaseClient _client = SupabaseService.client;
  final _uuid = const Uuid();

  String? get currentUserId => _client.auth.currentUser?.id ?? 'demo_user';

  // In-memory reactive stores
  final List<DatePlanModel> _localDatePlans = [];
  final List<BucketListItemModel> _localBucketList = [];
  final List<SharedGoalModel> _localSharedGoals = [];

  final _datePlansController = StreamController<List<DatePlanModel>>.broadcast();
  final _bucketListController = StreamController<List<BucketListItemModel>>.broadcast();
  final _sharedGoalsController = StreamController<List<SharedGoalModel>>.broadcast();

  void _initLocalData() {
    // Keep local lists empty for authentic couple creation
  }

  // ==========================================
  // 1. DATE PLANS
  // ==========================================
  List<DatePlanModel> getDatePlans(String relationshipId) {
    return List<DatePlanModel>.from(_localDatePlans)
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  Stream<List<DatePlanModel>> getDatePlansStream(String relationshipId) async* {
    yield getDatePlans(relationshipId);
    if (relationshipId.isNotEmpty) {
      try {
        final stream = _client
            .from('date_plans')
            .stream(primaryKey: ['id'])
            .eq('relationship_id', relationshipId)
            .order('scheduled_for', ascending: true)
            .map((data) {
              final remote = data.map((json) => DatePlanModel.fromJson(json)).toList();
              if (remote.isNotEmpty) {
                _localDatePlans.clear();
                _localDatePlans.addAll(remote);
              }
              return _localDatePlans;
            });
        yield* stream;
      } catch (_) {
        yield* _datePlansController.stream;
      }
    } else {
      yield* _datePlansController.stream;
    }
  }

  void _emitDatePlans() {
    if (!_datePlansController.isClosed) {
      _datePlansController.add(getDatePlans(''));
    }
  }


  Future<DatePlanModel> createDatePlan({
    required String relationshipId,
    required String title,
    String? description,
    required DateTime scheduledFor,
    String? locationName,
    double budget = 0.0,
    String category = 'Dinner',
  }) async {
    final newPlan = DatePlanModel(
      id: _uuid.v4(),
      relationshipId: relationshipId,
      createdBy: currentUserId ?? 'user_1',
      title: title,
      description: description,
      category: category,
      scheduledFor: scheduledFor,
      locationName: locationName,
      budget: budget,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    _localDatePlans.insert(0, newPlan);
    _emitDatePlans();

    try {
      await _client.from('date_plans').insert(newPlan.toJson());
    } catch (_) {}

    return newPlan;
  }

  Future<void> updateDatePlan(DatePlanModel updated) async {
    final idx = _localDatePlans.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _localDatePlans[idx] = updated;
      _emitDatePlans();
    }
    try {
      await _client.from('date_plans').update(updated.toJson()).eq('id', updated.id);
    } catch (_) {}
  }

  Future<void> toggleDatePlanCompleted(String planId, bool isCompleted) async {
    final idx = _localDatePlans.indexWhere((p) => p.id == planId);
    if (idx != -1) {
      _localDatePlans[idx] = _localDatePlans[idx].copyWith(isCompleted: isCompleted);
      _emitDatePlans();
    }
    try {
      await _client.from('date_plans').update({'is_completed': isCompleted}).eq('id', planId);
    } catch (_) {}
  }

  Future<void> deleteDatePlan(String planId) async {
    _localDatePlans.removeWhere((p) => p.id == planId);
    _emitDatePlans();
    try {
      await _client.from('date_plans').delete().eq('id', planId);
    } catch (_) {}
  }

  // ==========================================
  // 2. BUCKET LIST
  // ==========================================
  List<BucketListItemModel> getBucketList(String relationshipId) {
    return List<BucketListItemModel>.from(_localBucketList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<BucketListItemModel>> getBucketListStream(String relationshipId) async* {
    yield getBucketList(relationshipId);
    if (relationshipId.isNotEmpty) {
      try {
        final stream = _client
            .from('bucket_list')
            .stream(primaryKey: ['id'])
            .eq('relationship_id', relationshipId)
            .order('created_at', ascending: false)
            .map((data) {
              final remote = data.map((json) => BucketListItemModel.fromJson(json)).toList();
              if (remote.isNotEmpty) {
                _localBucketList.clear();
                _localBucketList.addAll(remote);
              }
              return _localBucketList;
            });
        yield* stream;
      } catch (_) {
        yield* _bucketListController.stream;
      }
    } else {
      yield* _bucketListController.stream;
    }
  }

  void _emitBucketList() {
    if (!_bucketListController.isClosed) {
      _bucketListController.add(getBucketList(''));
    }
  }

  Future<BucketListItemModel> createBucketListItem({
    required String relationshipId,
    required String title,
    String? description,
    String category = 'Travel',
    DateTime? targetDate,
  }) async {
    final newItem = BucketListItemModel(
      id: _uuid.v4(),
      relationshipId: relationshipId,
      createdBy: currentUserId ?? 'user_1',
      title: title,
      description: description,
      category: category,
      targetDate: targetDate,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    _localBucketList.insert(0, newItem);
    _emitBucketList();

    try {
      await _client.from('bucket_list').insert(newItem.toJson());
    } catch (_) {}

    return newItem;
  }

  Future<void> updateBucketListItem(BucketListItemModel updated) async {
    final idx = _localBucketList.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _localBucketList[idx] = updated;
      _emitBucketList();
    }
    try {
      await _client.from('bucket_list').update(updated.toJson()).eq('id', updated.id);
    } catch (_) {}
  }

  Future<void> toggleBucketItemCompleted(String itemId, bool isCompleted) async {
    final idx = _localBucketList.indexWhere((b) => b.id == itemId);
    if (idx != -1) {
      _localBucketList[idx] = _localBucketList[idx].copyWith(isCompleted: isCompleted);
      _emitBucketList();
    }
    try {
      await _client.from('bucket_list').update({'is_completed': isCompleted}).eq('id', itemId);
    } catch (_) {}
  }

  Future<void> deleteBucketListItem(String itemId) async {
    _localBucketList.removeWhere((b) => b.id == itemId);
    _emitBucketList();
    try {
      await _client.from('bucket_list').delete().eq('id', itemId);
    } catch (_) {}
  }

  // ==========================================
  // 3. SHARED GOALS
  // ==========================================
  List<SharedGoalModel> getSharedGoals(String relationshipId) {
    return List<SharedGoalModel>.from(_localSharedGoals)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<SharedGoalModel>> getSharedGoalsStream(String relationshipId) async* {
    yield getSharedGoals(relationshipId);
    if (relationshipId.isNotEmpty) {
      try {
        final stream = _client
            .from('shared_goals')
            .stream(primaryKey: ['id'])
            .eq('relationship_id', relationshipId)
            .order('created_at', ascending: false)
            .map((data) {
              final remote = data.map((json) => SharedGoalModel.fromJson(json)).toList();
              if (remote.isNotEmpty) {
                _localSharedGoals.clear();
                _localSharedGoals.addAll(remote);
              }
              return _localSharedGoals;
            });
        yield* stream;
      } catch (_) {
        yield* _sharedGoalsController.stream;
      }
    } else {
      yield* _sharedGoalsController.stream;
    }
  }

  void _emitSharedGoals() {
    if (!_sharedGoalsController.isClosed) {
      _sharedGoalsController.add(getSharedGoals(''));
    }
  }


  Future<SharedGoalModel> createSharedGoal({
    required String relationshipId,
    required String title,
    required double targetAmount,
    double currentAmount = 0.0,
    String category = 'Finance',
    DateTime? targetDate,
  }) async {
    final newGoal = SharedGoalModel(
      id: _uuid.v4(),
      relationshipId: relationshipId,
      createdBy: currentUserId ?? 'user_1',
      title: title,
      category: category,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      isCompleted: currentAmount >= targetAmount,
      createdAt: DateTime.now(),
    );

    _localSharedGoals.insert(0, newGoal);
    _emitSharedGoals();

    try {
      await _client.from('shared_goals').insert(newGoal.toJson());
    } catch (_) {}

    return newGoal;
  }

  Future<void> addGoalContribution(String goalId, double amount) async {
    final idx = _localSharedGoals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      final goal = _localSharedGoals[idx];
      final updatedAmount = goal.currentAmount + amount;
      final isCompleted = updatedAmount >= goal.targetAmount;
      _localSharedGoals[idx] = goal.copyWith(
        currentAmount: updatedAmount,
        isCompleted: isCompleted,
      );
      _emitSharedGoals();
      try {
        await _client.from('shared_goals').update({
          'current_amount': updatedAmount,
          'is_completed': isCompleted,
        }).eq('id', goalId);
      } catch (_) {}
    }
  }

  Future<void> updateSharedGoal(SharedGoalModel updated) async {
    final idx = _localSharedGoals.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _localSharedGoals[idx] = updated;
      _emitSharedGoals();
    }
    try {
      await _client.from('shared_goals').update(updated.toJson()).eq('id', updated.id);
    } catch (_) {}
  }

  Future<void> deleteSharedGoal(String goalId) async {
    _localSharedGoals.removeWhere((g) => g.id == goalId);
    _emitSharedGoals();
    try {
      await _client.from('shared_goals').delete().eq('id', goalId);
    } catch (_) {}
  }
}

