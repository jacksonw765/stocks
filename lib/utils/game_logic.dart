import '../models/player.dart';

/// Possible outcomes from a dice roll
enum RollOutcome {
  normal, // Regular roll, sum added to stock
  doubles, // Doubles rolled
  seven, // Seven rolled after roll 3 (round ends)
  seven70, // Seven rolled in first 3 rolls (+70 points)
}

/// Core game logic - stateless utility class
class GameLogic {
  /// Process a dice roll and return the outcome
  static RollOutcome processRoll({
    required int die1,
    required int die2,
    required int rollCount,
  }) {
    int sum = die1 + die2;
    bool isDoubles = die1 == die2;
    bool isFirstThreeRolls = rollCount <= 3;

    if (sum == 7) {
      return isFirstThreeRolls ? RollOutcome.seven70 : RollOutcome.seven;
    }
    if (isDoubles) {
      return RollOutcome.doubles;
    }
    return RollOutcome.normal;
  }

  /// Calculate new stock total after a roll
  static int calculateNewStockTotal({
    required int currentStock,
    required int die1,
    required int die2,
    required RollOutcome outcome,
    required int rollCount,
  }) {
    switch (outcome) {
      case RollOutcome.seven70:
        return currentStock + 70;
      case RollOutcome.seven:
        return 0; // Round ends
      case RollOutcome.doubles:
        if (rollCount <= 3) {
          // First 3 rolls: face value only
          return currentStock + die1 + die2;
        }
        // After roll 3: double the stock
        return currentStock * 2;
      case RollOutcome.normal:
        return currentStock + die1 + die2;
    }
  }

  /// Check if all active players have stocked
  static bool allPlayersStocked(List<Player> players) {
    return players.every((p) => p.hasStockedThisRound);
  }

  /// Get the next active roller index
  static int getNextRoller(List<Player> players, int current) {
    if (players.isEmpty) return 0;

    int next = (current + 1) % players.length;
    int attempts = 0;

    while (players[next].hasStockedThisRound && attempts < players.length) {
      next = (next + 1) % players.length;
      attempts++;
    }

    return next;
  }

  /// Determine winner(s)
  static List<Player> getWinners(List<Player> players) {
    if (players.isEmpty) return [];

    int maxScore = players
        .map((p) => p.totalScore)
        .reduce((a, b) => a > b ? a : b);

    return players.where((p) => p.totalScore == maxScore).toList();
  }

  /// Points needed to take the lead
  static int pointsToLead(Player player, List<Player> all) {
    if (all.length <= 1) return 0;

    int maxOther = all
        .where((p) => p.id != player.id)
        .map((p) => p.totalScore)
        .fold(0, (a, b) => a > b ? a : b);

    int deficit = maxOther - player.totalScore;
    return deficit > 0 ? deficit + 1 : 0;
  }

  /// Get description text for a roll outcome
  static String getRollDescription(
    RollOutcome outcome,
    int die1,
    int die2,
    int rollCount,
  ) {
    int sum = die1 + die2;

    switch (outcome) {
      case RollOutcome.seven70:
        return '7 in first 3 rolls! +70 points!';
      case RollOutcome.seven:
        return 'Seven rolled! Round over!';
      case RollOutcome.doubles:
        if (rollCount <= 3) {
          return 'Doubles! +$sum (face value only)';
        }
        return 'DOUBLES! Stock doubled!';
      case RollOutcome.normal:
        return 'Rolled $sum';
    }
  }
}
