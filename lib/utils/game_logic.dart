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

  // ==========================================================================
  // PROBABILITY HELPERS (Based on Monte Carlo simulation data)
  // ==========================================================================

  /// Probability of rolling a 7 on any single roll (6/36 = 16.67%)
  static const double sevenProbability = 0.1667;

  /// Probability of rolling doubles on any single roll (6/36 = 16.67%)
  static const double doublesProbability = 0.1667;

  /// Survival probability after N rolls (probability of NOT having rolled a 7 yet)
  /// Based on: (5/6)^(n-3) for rolls after the safe zone
  static double getSurvivalProbability(int rollCount) {
    if (rollCount <= 3) return 1.0; // Safe zone, 7 is +70
    // Probability of surviving each roll after 3 is 5/6
    int riskyRolls = rollCount - 3;
    return _pow5_6(riskyRolls);
  }

  /// Helper: (5/6)^n
  static double _pow5_6(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= (5.0 / 6.0);
    }
    return result;
  }

  /// Survival probability data for common roll counts
  static const Map<int, double> survivalByRoll = {
    4: 0.833,
    5: 0.694,
    6: 0.579,
    7: 0.482,
    8: 0.402,
    9: 0.335,
    10: 0.279,
    11: 0.233,
    12: 0.194,
  };

  /// Get a recommendation based on current stock total and roll count
  static StockRecommendation getRecommendation({
    required int stockTotal,
    required int rollCount,
    required int pointsDeficit,
    required bool isLeading,
  }) {
    // In safe zone (rolls 1-3), always keep rolling unless massive stock
    if (rollCount <= 3) {
      return StockRecommendation(
        action: RecommendedAction.keepRolling,
        reason: 'Safe zone! 7 gives +70',
        confidence: Confidence.high,
      );
    }

    // Calculate expected bust cost
    double bustCost = stockTotal * sevenProbability;

    // Thresholds based on Monte Carlo simulation sweet spots
    if (stockTotal >= 150) {
      return StockRecommendation(
        action: isLeading
            ? RecommendedAction.stock
            : RecommendedAction.consider,
        reason:
            'High value at risk (${bustCost.toStringAsFixed(0)} EV loss if 7)',
        confidence: Confidence.high,
      );
    }

    if (stockTotal >= 100) {
      if (isLeading) {
        return StockRecommendation(
          action: RecommendedAction.consider,
          reason: 'Good bank. Leading = protect it',
          confidence: Confidence.medium,
        );
      }
      return StockRecommendation(
        action: RecommendedAction.keepRolling,
        reason: 'Solid stock, but not leading',
        confidence: Confidence.medium,
      );
    }

    if (stockTotal >= 60) {
      return StockRecommendation(
        action: RecommendedAction.keepRolling,
        reason: 'Moderate stock, EV positive',
        confidence: Confidence.medium,
      );
    }

    // Low stock - definitely keep rolling
    return StockRecommendation(
      action: RecommendedAction.keepRolling,
      reason: 'Low stock, worth the risk',
      confidence: Confidence.high,
    );
  }

  /// Get formatted survival percentage for display
  static String getSurvivalText(int rollCount) {
    if (rollCount <= 3) return '100%'; // Safe zone
    final survival = getSurvivalProbability(rollCount);
    return '${(survival * 100).toStringAsFixed(1)}%';
  }

  /// Get the expected bust cost (what you'd lose on average if you roll again)
  static double getExpectedBustCost(int stockTotal) {
    return stockTotal * sevenProbability;
  }

  /// Get odds text for display
  static String getSevenOddsText() => '16.7% (1 in 6)';
}

/// Recommendation data structure
class StockRecommendation {
  final RecommendedAction action;
  final String reason;
  final Confidence confidence;

  StockRecommendation({
    required this.action,
    required this.reason,
    required this.confidence,
  });
}

enum RecommendedAction { keepRolling, consider, stock }

enum Confidence { low, medium, high }
