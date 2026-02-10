import 'player.dart';
import '../utils/game_logic.dart';

/// A single roll entry in the game's history
class RollHistoryEntry {
  final int die1;
  final int die2;
  final RollOutcome outcome;
  final int stockTotal;
  final int round;
  final String rollerId;
  final String rollerName;

  const RollHistoryEntry({
    required this.die1,
    required this.die2,
    required this.outcome,
    required this.stockTotal,
    required this.round,
    required this.rollerId,
    required this.rollerName,
  });
}

/// Encapsulates the entire state of an active game session
class GameState {
  List<Player> players;
  int currentRound;
  int totalRounds; // 10, 15, or 20
  int stockTotal; // Cumulative stock for current round
  int rollCount; // Rolls in current round
  int currentRollerIndex; // Whose turn to roll
  int die1;
  int die2;
  bool roundActive;
  bool gameOver;
  bool oneStockPerRoll; // Variant rule
  bool someoneStockedThisRoll; // For variant rule

  /// Full roll history across all rounds in this game session
  List<RollHistoryEntry> rollHistory;

  GameState({
    required this.players,
    this.totalRounds = 20,
    this.currentRound = 1,
    this.stockTotal = 0,
    this.rollCount = 0,
    this.currentRollerIndex = 0,
    this.die1 = 0,
    this.die2 = 0,
    this.roundActive = true,
    this.gameOver = false,
    this.oneStockPerRoll = false,
    this.someoneStockedThisRoll = false,
    List<RollHistoryEntry>? rollHistory,
  }) : rollHistory = rollHistory ?? [];

  /// Get the current roller
  Player? get currentRoller =>
      players.isNotEmpty ? players[currentRollerIndex] : null;

  /// Check if all players have stocked
  bool get allPlayersStocked => players.every((p) => p.hasStockedThisRound);

  /// Get players sorted by score (descending)
  List<Player> get playersByScore {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted;
  }

  /// Get the leading score
  int get leadingScore {
    if (players.isEmpty) return 0;
    return players.map((p) => p.totalScore).reduce((a, b) => a > b ? a : b);
  }

  /// Reset state for a new round
  void resetForNewRound() {
    currentRound++;
    stockTotal = 0;
    rollCount = 0;
    roundActive = true;
    someoneStockedThisRoll = false;
    die1 = 0;
    die2 = 0;
    for (var p in players) {
      p.resetForNewRound();
    }
  }

  /// Get rolls for a specific player
  List<RollHistoryEntry> rollsForPlayer(String playerId) {
    return rollHistory.where((e) => e.rollerId == playerId).toList();
  }

  /// Create a copy of this game state
  GameState copyWith({
    List<Player>? players,
    int? currentRound,
    int? totalRounds,
    int? stockTotal,
    int? rollCount,
    int? currentRollerIndex,
    int? die1,
    int? die2,
    bool? roundActive,
    bool? gameOver,
    bool? oneStockPerRoll,
    bool? someoneStockedThisRoll,
    List<RollHistoryEntry>? rollHistory,
  }) {
    return GameState(
      players: players ?? this.players,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      stockTotal: stockTotal ?? this.stockTotal,
      rollCount: rollCount ?? this.rollCount,
      currentRollerIndex: currentRollerIndex ?? this.currentRollerIndex,
      die1: die1 ?? this.die1,
      die2: die2 ?? this.die2,
      roundActive: roundActive ?? this.roundActive,
      gameOver: gameOver ?? this.gameOver,
      oneStockPerRoll: oneStockPerRoll ?? this.oneStockPerRoll,
      someoneStockedThisRoll:
          someoneStockedThisRoll ?? this.someoneStockedThisRoll,
      rollHistory: rollHistory ?? List.from(this.rollHistory),
    );
  }
}
