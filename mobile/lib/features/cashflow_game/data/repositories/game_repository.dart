import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';
import 'package:fin_goal/features/cashflow_game/data/datasources/occupations_data.dart';

class GameRepository {
  final SharedPreferences _prefs;
  static const _keyPrefix = 'cashflow_game_v2_';

  GameRepository(this._prefs);

  Future<GameState?> loadGame(String playerId) async {
    final raw = _prefs.getString('$_keyPrefix$playerId');
    if (raw == null) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return _fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGame(GameState state) async {
    await _prefs.setString(
      '$_keyPrefix${state.playerId}',
      json.encode(state.toJson()),
    );
  }

  Future<void> deleteGame(String playerId) async {
    await _prefs.remove('$_keyPrefix$playerId');
  }

  GameState _fromJson(Map<String, dynamic> map) {
    final occupation = occupations.firstWhere(
      (o) => o.id == map['occupationId'],
      orElse: () => occupations.first,
    );
    return GameState(
      playerId: map['playerId'] as String,
      occupation: occupation,
      boardPosition: map['boardPosition'] as int? ?? 0,
      currentTurn: map['currentTurn'] as int? ?? 0,
      downsizeTurns: map['downsizeTurns'] as int? ?? 0,
      cashOnHand: map['cashOnHand'] as int,
      monthlyIncome: map['monthlyIncome'] as int,
      monthlyExpenses: map['monthlyExpenses'] as int,
      children: map['children'] as int? ?? 0,
      creditScore: map['creditScore'] as int? ?? 650,
      economyState: EconomyState.values.byName(
        map['economyState'] as String? ?? 'normal',
      ),
      inflationRate: (map['inflationRate'] as num?)?.toDouble() ?? 0.03,
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      assets: (map['assets'] as List<dynamic>?)
              ?.map((a) => _assetFromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      liabilities: (map['liabilities'] as List<dynamic>?)
              ?.map((l) => _liabilityFromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Asset _assetFromJson(Map<String, dynamic> m) => Asset(
        id: m['id'] as String,
        name: m['name'] as String,
        type: AssetType.values.byName(m['type'] as String),
        purchasePrice: m['purchasePrice'] as int,
        currentValue: m['currentValue'] as int,
        monthlyPassiveIncome: m['monthlyPassiveIncome'] as int,
        downPayment: m['downPayment'] as int? ?? 0,
        mortgage: m['mortgage'] as int? ?? 0,
        monthlyMortgagePayment: m['monthlyMortgagePayment'] as int? ?? 0,
      );

  Liability _liabilityFromJson(Map<String, dynamic> m) => Liability(
        id: m['id'] as String,
        name: m['name'] as String,
        totalOwed: m['totalOwed'] as int,
        monthlyPayment: m['monthlyPayment'] as int,
      );
}
