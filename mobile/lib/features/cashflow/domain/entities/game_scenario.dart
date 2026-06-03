import 'package:equatable/equatable.dart';

import 'cashflow_state.dart';

class GameImpact extends Equatable {
  final int cashChange;
  final int activeIncomeChange;
  final int baseExpensesChange;
  
  final List<CashflowAsset>? addedAssets;
  final List<String>? removedAssetIds;
  
  final List<CashflowLiability>? addedLiabilities;
  final List<String>? removedLiabilityIds;

  const GameImpact({
    this.cashChange = 0,
    this.activeIncomeChange = 0,
    this.baseExpensesChange = 0,
    this.addedAssets,
    this.removedAssetIds,
    this.addedLiabilities,
    this.removedLiabilityIds,
  });

  @override
  List<Object?> get props => [
        cashChange,
        activeIncomeChange,
        baseExpensesChange,
        addedAssets,
        removedAssetIds,
        addedLiabilities,
        removedLiabilityIds,
      ];

  Map<String, dynamic> toJson() => {
        'cashChange': cashChange,
        'activeIncomeChange': activeIncomeChange,
        'baseExpensesChange': baseExpensesChange,
        'addedAssets': addedAssets?.map((e) => e.toJson()).toList(),
        'removedAssetIds': removedAssetIds,
        'addedLiabilities': addedLiabilities?.map((e) => e.toJson()).toList(),
        'removedLiabilityIds': removedLiabilityIds,
      };

  factory GameImpact.fromJson(Map<String, dynamic> json) => GameImpact(
        cashChange: json['cashChange'] as int? ?? 0,
        activeIncomeChange: json['activeIncomeChange'] as int? ?? 0,
        baseExpensesChange: json['baseExpensesChange'] as int? ?? 0,
        addedAssets: (json['addedAssets'] as List<dynamic>?)
            ?.map((e) => CashflowAsset.fromJson(e as Map<String, dynamic>))
            .toList(),
        removedAssetIds: (json['removedAssetIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        addedLiabilities: (json['addedLiabilities'] as List<dynamic>?)
            ?.map((e) => CashflowLiability.fromJson(e as Map<String, dynamic>))
            .toList(),
        removedLiabilityIds: (json['removedLiabilityIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}

class GameOption extends Equatable {
  final String id;
  final String title;
  final String description;
  final GameImpact impact;
  
  /// Đánh giá của AI về lựa chọn này (ẩn cho đến khi user chọn)
  final String aiFeedback;

  const GameOption({
    required this.id,
    required this.title,
    required this.description,
    required this.impact,
    required this.aiFeedback,
  });

  @override
  List<Object?> get props => [id, title, description, impact, aiFeedback];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'impact': impact.toJson(),
        'aiFeedback': aiFeedback,
      };

  factory GameOption.fromJson(Map<String, dynamic> json) => GameOption(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        impact: GameImpact.fromJson(json['impact'] as Map<String, dynamic>),
        aiFeedback: json['aiFeedback'] as String,
      );
}

class GameScenario extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<GameOption> options;

  const GameScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });

  @override
  List<Object?> get props => [id, title, description, options];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'options': options.map((e) => e.toJson()).toList(),
      };

  factory GameScenario.fromJson(Map<String, dynamic> json) => GameScenario(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        options: (json['options'] as List<dynamic>)
            .map((e) => GameOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
