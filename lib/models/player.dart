/// Represents a single player in the game
class Player {
  final String id;
  final String name;
  int totalScore;
  int currentRoundStock;
  bool hasStockedThisRound;
  bool isActiveRoller;
  int allTimeHighestStock;
  int gamesPlayed;
  int gamesWon;

  Player({
    required this.id,
    required this.name,
    this.totalScore = 0,
    this.currentRoundStock = 0,
    this.hasStockedThisRound = false,
    this.isActiveRoller = true,
    this.allTimeHighestStock = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });

  /// Lock in the current stock total as points for this round
  void stockPoints(int stockTotal) {
    currentRoundStock = stockTotal;
    totalScore += stockTotal;
    hasStockedThisRound = true;
    isActiveRoller = false;
    if (stockTotal > allTimeHighestStock) {
      allTimeHighestStock = stockTotal;
    }
  }

  /// Reset player state for a new round
  void resetForNewRound() {
    currentRoundStock = 0;
    hasStockedThisRound = false;
    isActiveRoller = true;
  }

  /// Reset player state for a new game
  void resetForNewGame() {
    totalScore = 0;
    currentRoundStock = 0;
    hasStockedThisRound = false;
    isActiveRoller = true;
  }

  /// Create a copy of this player
  Player copyWith({
    String? id,
    String? name,
    int? totalScore,
    int? currentRoundStock,
    bool? hasStockedThisRound,
    bool? isActiveRoller,
    int? allTimeHighestStock,
    int? gamesPlayed,
    int? gamesWon,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalScore: totalScore ?? this.totalScore,
      currentRoundStock: currentRoundStock ?? this.currentRoundStock,
      hasStockedThisRound: hasStockedThisRound ?? this.hasStockedThisRound,
      isActiveRoller: isActiveRoller ?? this.isActiveRoller,
      allTimeHighestStock: allTimeHighestStock ?? this.allTimeHighestStock,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'allTimeHighestStock': allTimeHighestStock,
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
  };

  /// Create from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      allTimeHighestStock: json['allTimeHighestStock'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
