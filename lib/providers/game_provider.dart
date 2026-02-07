import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../utils/game_logic.dart';
import '../utils/storage_helper.dart';

/// Main game state provider
class GameProvider extends ChangeNotifier {
  GameState _state;
  RollOutcome? _lastOutcome;
  String _lastRollDescription = '';

  GameProvider(this._state);

  GameState get state => _state;
  RollOutcome? get lastOutcome => _lastOutcome;
  String get lastRollDescription => _lastRollDescription;

  /// Enter a dice roll
  void enterRoll(int die1, int die2) {
    _state.die1 = die1;
    _state.die2 = die2;
    _state.rollCount++;

    final outcome = GameLogic.processRoll(
      die1: die1,
      die2: die2,
      rollCount: _state.rollCount,
    );

    _lastOutcome = outcome;
    _lastRollDescription = GameLogic.getRollDescription(
      outcome,
      die1,
      die2,
      _state.rollCount,
    );

    _state.stockTotal = GameLogic.calculateNewStockTotal(
      currentStock: _state.stockTotal,
      die1: die1,
      die2: die2,
      outcome: outcome,
      rollCount: _state.rollCount,
    );

    if (outcome == RollOutcome.seven) {
      endRound();
      return;
    }

    _state.someoneStockedThisRoll = false;
    _state.currentRollerIndex = GameLogic.getNextRoller(
      _state.players,
      _state.currentRollerIndex,
    );
    notifyListeners();
  }

  /// Player stocks their points
  void stockPlayer(String playerId) {
    if (_state.oneStockPerRoll && _state.someoneStockedThisRoll) {
      return; // Only one stock per roll in variant mode
    }

    final player = _state.players.firstWhere((p) => p.id == playerId);
    player.stockPoints(_state.stockTotal);
    _state.someoneStockedThisRoll = true;

    if (GameLogic.allPlayersStocked(_state.players)) {
      endRound();
    } else {
      // Update roller if current player stocked
      if (_state.players[_state.currentRollerIndex].hasStockedThisRound) {
        _state.currentRollerIndex = GameLogic.getNextRoller(
          _state.players,
          _state.currentRollerIndex,
        );
      }
    }
    notifyListeners();
  }

  /// End the current round
  void endRound() {
    _state.roundActive = false;
    if (_state.currentRound >= _state.totalRounds) {
      _state.gameOver = true;
      _saveGameResults();
    }
    notifyListeners();
  }

  /// Start the next round
  void startNextRound() {
    _state.resetForNewRound();
    _lastOutcome = null;
    _lastRollDescription = '';
    notifyListeners();
  }

  /// Save game results to player records
  Future<void> _saveGameResults() async {
    final winners = GameLogic.getWinners(_state.players);
    for (var player in _state.players) {
      final isWinner = winners.any((w) => w.id == player.id);
      await StorageHelper.updatePlayerRecord(player, isWinner);
    }
  }

  /// Reset for a new game with same players
  void playAgain() {
    for (var player in _state.players) {
      player.resetForNewGame();
    }
    _state = GameState(
      players: _state.players,
      totalRounds: _state.totalRounds,
      oneStockPerRoll: _state.oneStockPerRoll,
    );
    _lastOutcome = null;
    _lastRollDescription = '';
    notifyListeners();
  }

  /// Get points needed for a player to take the lead
  int pointsToLead(Player player) {
    return GameLogic.pointsToLead(player, _state.players);
  }

  /// Get the list of winners
  List<Player> getWinners() {
    return GameLogic.getWinners(_state.players);
  }
}
