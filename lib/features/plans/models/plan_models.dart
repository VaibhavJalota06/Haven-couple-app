import 'package:equatable/equatable.dart';

// Date Plan Model
class DatePlanModel extends Equatable {
  final String id;
  final String relationshipId;
  final String createdBy;
  final String title;
  final String? description;
  final String category;
  final DateTime scheduledFor;
  final String? locationName;
  final double budget;
  final String currency;
  final bool isCompleted;
  final DateTime createdAt;

  const DatePlanModel({
    required this.id,
    required this.relationshipId,
    required this.createdBy,
    required this.title,
    this.description,
    this.category = 'dinner',
    required this.scheduledFor,
    this.locationName,
    this.budget = 0.0,
    this.currency = 'USD',
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationship_id': relationshipId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        'category': category,
        'scheduled_for': scheduledFor.toIso8601String(),
        'location_name': locationName,
        'budget': budget,
        'currency': currency,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
      };

  factory DatePlanModel.fromJson(Map<String, dynamic> json) => DatePlanModel(
        id: json['id'] as String,
        relationshipId: json['relationship_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String? ?? 'Date Night',
        description: json['description'] as String?,
        category: json['category'] as String? ?? 'dinner',
        scheduledFor: json['scheduled_for'] != null
            ? DateTime.parse(json['scheduled_for'] as String)
            : DateTime.now(),
        locationName: json['location_name'] as String?,
        budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'USD',
        isCompleted: json['is_completed'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  DatePlanModel copyWith({
    String? id,
    String? relationshipId,
    String? createdBy,
    String? title,
    String? description,
    String? category,
    DateTime? scheduledFor,
    String? locationName,
    double? budget,
    String? currency,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return DatePlanModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      locationName: locationName ?? this.locationName,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, relationshipId, title, scheduledFor, isCompleted];
}

// Bucket List Item Model
class BucketListItemModel extends Equatable {
  final String id;
  final String relationshipId;
  final String createdBy;
  final String title;
  final String? description;
  final String category;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;

  const BucketListItemModel({
    required this.id,
    required this.relationshipId,
    required this.createdBy,
    required this.title,
    this.description,
    this.category = 'travel',
    this.targetDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationship_id': relationshipId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        'category': category,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
      };

  factory BucketListItemModel.fromJson(Map<String, dynamic> json) => BucketListItemModel(
        id: json['id'] as String,
        relationshipId: json['relationship_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String? ?? 'Bucket List Item',
        description: json['description'] as String?,
        category: json['category'] as String? ?? 'travel',
        targetDate: json['target_date'] != null
            ? DateTime.tryParse(json['target_date'] as String)
            : null,
        isCompleted: json['is_completed'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  BucketListItemModel copyWith({
    String? id,
    String? relationshipId,
    String? createdBy,
    String? title,
    String? description,
    String? category,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return BucketListItemModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, relationshipId, title, isCompleted];
}

// Shared Goal Model
class SharedGoalModel extends Equatable {
  final String id;
  final String relationshipId;
  final String createdBy;
  final String title;
  final String category;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;

  const SharedGoalModel({
    required this.id,
    required this.relationshipId,
    required this.createdBy,
    required this.title,
    this.category = 'finance',
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.currency = 'USD',
    this.targetDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationship_id': relationshipId,
        'created_by': createdBy,
        'title': title,
        'category': category,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'currency': currency,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
      };

  factory SharedGoalModel.fromJson(Map<String, dynamic> json) => SharedGoalModel(
        id: json['id'] as String,
        relationshipId: json['relationship_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String? ?? 'Shared Goal',
        category: json['category'] as String? ?? 'finance',
        targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 1000.0,
        currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'USD',
        targetDate: json['target_date'] != null
            ? DateTime.tryParse(json['target_date'] as String)
            : null,
        isCompleted: json['is_completed'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  SharedGoalModel copyWith({
    String? id,
    String? relationshipId,
    String? createdBy,
    String? title,
    String? category,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SharedGoalModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, relationshipId, title, currentAmount, targetAmount, isCompleted];
}

