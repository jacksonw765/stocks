import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/game_logic.dart';
import '../utils/storage_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_total_display.dart';
import '../widgets/number_pad.dart';
import '../widgets/player_score_card.dart';
import '../widgets/dice_display.dart';
import '../widgets/market_crash_overlay.dart';

/// Game flow stages
enum _GameStage { setup, playing, roundSummary, gameOver }

/// Game flow manages the entire game session including setup, gameplay, and results
class GameFlowScreen extends StatefulWidget {
  const GameFlowScreen({super.key});

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  _GameStage _stage = _GameStage.setup;
  GameProvider? _gameProvider;

  // Setup state
  final _nameController = TextEditingController();
  final List<String> _players = [];
  List<String> _savedPlayers = [];
  bool _isLoadingSaved = true;
  int _totalRounds = 20;
  bool _oneStockPerRoll = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPlayers();
    _loadSettings();
  }

  Future<void> _loadSavedPlayers() async {
    final saved = await StorageHelper.getSavedPlayerNames();
    setState(() {
      _savedPlayers = saved;
      _isLoadingSaved = false;
    });
  }

  Future<void> _loadSettings() async {
    final settings = context.read<SettingsProvider>();
    setState(() {
      _totalRounds = settings.totalRounds;
      _oneStockPerRoll = settings.oneStockPerRoll;
    });
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_players.contains(name)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Player already added')));
      return;
    }
    setState(() {
      _players.add(name);
      if (!_savedPlayers.contains(name)) {
        _savedPlayers.add(name);
        StorageHelper.addPlayerName(name);
      }
    });
    _nameController.clear();
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  void _addSavedPlayer(String name) {
    if (_players.contains(name)) return;
    setState(() => _players.add(name));
  }

  void _startGame() {
    if (_players.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Need at least 2 players')));
      return;
    }

    final players = _players
        .map((name) => Player(id: UniqueKey().toString(), name: name))
        .toList();

    final gameState = GameState(
      players: players,
      totalRounds: _totalRounds,
      oneStockPerRoll: _oneStockPerRoll,
    );

    setState(() {
      _gameProvider = GameProvider(gameState);
      _stage = _GameStage.playing;
    });
  }

  void _showRoundSummary() {
    setState(() => _stage = _GameStage.roundSummary);
  }

  void _showGameOver() {
    setState(() => _stage = _GameStage.gameOver);
  }

  void _nextRound() {
    _gameProvider!.startNextRound();
    setState(() => _stage = _GameStage.playing);
  }

  void _playAgain() {
    _gameProvider!.playAgain();
    setState(() => _stage = _GameStage.playing);
  }

  void _goHome() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Determine transition based on stage
        final currentStage = (child.key as ValueKey<_GameStage>).value;

        switch (currentStage) {
          case _GameStage.setup:
            // Setup slides in from left, fades out
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          case _GameStage.playing:
            // Playing slides in from right
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          case _GameStage.roundSummary:
            // Round summary zooms in with fade
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          case _GameStage.gameOver:
            // Game over scales up dramatically
            return ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
        }
      },
      child: _buildStageWidget(),
    );
  }

  Widget _buildStageWidget() {
    switch (_stage) {
      case _GameStage.setup:
        return KeyedSubtree(
          key: const ValueKey(_GameStage.setup),
          child: _buildSetupScreen(),
        );
      case _GameStage.playing:
        return KeyedSubtree(
          key: const ValueKey(_GameStage.playing),
          child: ChangeNotifierProvider.value(
            value: _gameProvider!,
            child: _GamePlayScreen(
              onRoundEnd: _showRoundSummary,
              onExit: _goHome,
            ),
          ),
        );
      case _GameStage.roundSummary:
        return KeyedSubtree(
          key: const ValueKey(_GameStage.roundSummary),
          child: ChangeNotifierProvider.value(
            value: _gameProvider!,
            child: _RoundSummaryView(
              onNextRound: _nextRound,
              onGameOver: _showGameOver,
            ),
          ),
        );
      case _GameStage.gameOver:
        return KeyedSubtree(
          key: const ValueKey(_GameStage.gameOver),
          child: ChangeNotifierProvider.value(
            value: _gameProvider!,
            child: _GameOverView(onPlayAgain: _playAgain, onHome: _goHome),
          ),
        );
    }
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Players'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter player name',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _addPlayer, child: const Text('Add')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Players label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Players (${_players.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (_players.length < 2)
                  Text(
                    '• Need ${2 - _players.length} more',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Current players list
          Expanded(
            child: _players.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add players to start',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _players.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final player = _players.removeAt(oldIndex);
                        _players.insert(newIndex, player);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Card(
                        key: ValueKey(_players[index]),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            _players[index],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removePlayer(index),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Saved players section
          if (!_isLoadingSaved && _savedPlayers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Add',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _savedPlayers
                        .where((name) => !_players.contains(name))
                        .take(6)
                        .map(
                          (name) => ActionChip(
                            label: Text(name),
                            onPressed: () => _addSavedPlayer(name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // Start button
          Container(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _players.length >= 2 ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(
                        _players.length >= 2
                            ? 'Start Game'
                            : 'Add at least 2 players',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

// ============================================================================
// GAMEPLAY SCREEN
// ============================================================================

class _GamePlayScreen extends StatefulWidget {
  final VoidCallback onRoundEnd;
  final VoidCallback onExit;

  const _GamePlayScreen({required this.onRoundEnd, required this.onExit});

  @override
  State<_GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<_GamePlayScreen> {
  bool _showingCrash = false;
  bool _roundEndHandled = false;
  final PanelController _panelController = PanelController();

  void _showStockConfirmation(
    BuildContext context,
    String playerId,
    String playerName,
    int stockTotal,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              playerName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock $stockTotal points?',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          selectionColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<GameProvider>().stockPlayer(playerId);
                          Navigator.pop(ctx);
                        },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Confirm'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onExit();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppTheme.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRoundEnd(bool wasSevenRolled) {
    if (_roundEndHandled) return;
    _roundEndHandled = true;

    if (wasSevenRolled) {
      // Show crash animation first
      setState(() => _showingCrash = true);
    } else {
      // Normal round end (all stocked), go directly to summary
      widget.onRoundEnd();
    }
  }

  void _onCrashComplete() {
    setState(() => _showingCrash = false);
    widget.onRoundEnd();
  }

  Color _getDescriptionColor(RollOutcome? outcome) {
    switch (outcome) {
      case RollOutcome.seven:
        return AppTheme.dangerRed;
      case RollOutcome.doubles:
        return AppTheme.successGreen;
      case RollOutcome.seven70:
        return AppTheme.accentGold;
      default:
        return Colors.grey;
    }
  }

  void _showStatsModal(
    BuildContext context,
    int rollCount,
    int stockTotal,
    bool isLeading,
  ) {
    final recommendation = GameLogic.getRecommendation(
      stockTotal: stockTotal,
      rollCount: rollCount,
      pointsDeficit: 0,
      isLeading: isLeading,
    );

    final survivalPct = GameLogic.getSurvivalText(rollCount + 1);
    final bustCost = GameLogic.getExpectedBustCost(stockTotal);
    final inSafeZone = rollCount < 3;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'Roll Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  Icons.casino,
                  '7 Odds',
                  '16.7%',
                  inSafeZone ? AppTheme.successGreen : AppTheme.dangerRed,
                ),
                _buildStatColumn(
                  Icons.favorite,
                  'Survival',
                  survivalPct,
                  _getSurvivalColor(rollCount + 1),
                ),
                _buildStatColumn(
                  Icons.warning_amber,
                  'Bust Cost',
                  bustCost.toStringAsFixed(0),
                  bustCost > 15 ? AppTheme.dangerRed : AppTheme.accentGold,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Recommendation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRecommendationColor(
                  recommendation.action,
                ).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRecommendationColor(
                    recommendation.action,
                  ).withAlpha(77),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getRecommendationIcon(recommendation.action),
                    size: 28,
                    color: _getRecommendationColor(recommendation.action),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRecommendationText(recommendation.action),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getRecommendationColor(recommendation.action),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getSurvivalColor(int nextRoll) {
    if (nextRoll <= 3) return AppTheme.successGreen;
    final survival = GameLogic.getSurvivalProbability(nextRoll);
    if (survival > 0.6) return AppTheme.successGreen;
    if (survival > 0.4) return AppTheme.accentGold;
    return AppTheme.dangerRed;
  }

  Color _getRecommendationColor(RecommendedAction action) {
    switch (action) {
      case RecommendedAction.keepRolling:
        return AppTheme.successGreen;
      case RecommendedAction.consider:
        return AppTheme.accentGold;
      case RecommendedAction.stock:
        return AppTheme.dangerRed;
    }
  }

  IconData _getRecommendationIcon(RecommendedAction action) {
    switch (action) {
      case RecommendedAction.keepRolling:
        return Icons.play_arrow;
      case RecommendedAction.consider:
        return Icons.psychology;
      case RecommendedAction.stock:
        return Icons.savings;
    }
  }

  String _getRecommendationText(RecommendedAction action) {
    switch (action) {
      case RecommendedAction.keepRolling:
        return 'Keep Rolling';
      case RecommendedAction.consider:
        return 'Consider Stocking';
      case RecommendedAction.stock:
        return 'Stock Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final state = game.state;

        // Check if round ended
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!state.roundActive && !_roundEndHandled && !_showingCrash) {
            final wasSevenRolled =
                state.die1 + state.die2 == 7 && state.rollCount > 3;
            _handleRoundEnd(wasSevenRolled);
          }
        });

        return Stack(
          children: [
            // Main game UI
            Scaffold(
              appBar: AppBar(
                toolbarHeight: 40,
                title: Text(
                  'Round ${state.currentRound} of ${state.totalRounds}',
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _showExitConfirmation(context),
                ),
                actions: [
                  // Stats modal button
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined),
                    onPressed: () => _showStatsModal(
                      context,
                      state.rollCount,
                      state.stockTotal,
                      state.currentRoller != null &&
                          state.currentRoller!.totalScore >= state.leadingScore,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => Navigator.pushNamed(context, '/rules'),
                  ),
                ],
              ),
              body: SlidingUpPanel(
                controller: _panelController,
                minHeight: 50,
                maxHeight: 200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                defaultPanelState: PanelState.OPEN,
                panel: NumberPad(
                  onRollEntered: (die1, die2) {
                    game.enterRoll(die1, die2);
                  },
                  onMinimize: () => _panelController.close(),
                ),
                collapsed: GestureDetector(
                  onTap: () => _panelController.open(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Drag up to enter roll',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                body: Column(
                  children: [
                    // Current roller banner
                    if (state.currentRoller != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: AppTheme.primaryColor.withAlpha(26),
                        child: Text(
                          '${state.currentRoller!.name}\'s turn to roll',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Stock total display
                    StockTotalDisplay(
                      total: state.stockTotal,
                      lastOutcome: game.lastOutcome,
                      rollCount: state.rollCount,
                      rollHistory: state.rollHistory,
                      currentRollerId: state.currentRoller?.id,
                      currentRollerName: state.currentRoller?.name,
                    ),

                    const SizedBox(height: 12),

                    // Dice display - always visible
                    DiceDisplay(
                      die1: state.die1 > 0 ? state.die1 : 0,
                      die2: state.die2 > 0 ? state.die2 : 0,
                      isDoubles: state.die1 > 0 && state.die1 == state.die2,
                      isSeven: state.die1 > 0 && state.die1 + state.die2 == 7 && state.rollCount > 3,
                      isSafeSeven: state.die1 > 0 && state.die1 + state.die2 == 7 && state.rollCount <= 3,
                      showPlaceholder: state.die1 == 0,
                    ),
                    if (state.die1 > 0 && state.die2 > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        game.lastRollDescription,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getDescriptionColor(game.lastOutcome),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Player list
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.players.length,
                        padding: const EdgeInsets.only(bottom: 160),
                        itemBuilder: (context, index) {
                          final player = state.players[index];
                          return PlayerScoreCard(
                            player: player,
                            stockTotal: state.stockTotal,
                            leadScore: state.leadingScore,
                            isCurrentRoller: index == state.currentRollerIndex,
                            onStock: () => _showStockConfirmation(
                              context,
                              player.id,
                              player.name,
                              state.stockTotal,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Crash overlay
            if (_showingCrash)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(178),
                  child: MarketCrashOverlay(onComplete: _onCrashComplete),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// ROUND SUMMARY VIEW
// ============================================================================

class _RoundSummaryView extends StatefulWidget {
  final VoidCallback onNextRound;
  final VoidCallback onGameOver;

  const _RoundSummaryView({
    required this.onNextRound,
    required this.onGameOver,
  });

  @override
  State<_RoundSummaryView> createState() => _RoundSummaryViewState();
}

class _RoundSummaryViewState extends State<_RoundSummaryView>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _buttonController;
  late Animation<double> _headerScale;
  late Animation<double> _headerFade;
  late Animation<double> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _buttonSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );

    // Stagger the animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Animation<double> _getCardAnimation(int index, int totalCards) {
    // Each card animates in sequence
    final start = (index / totalCards) * 0.6;
    final end = start + 0.4;
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final state = game.state;

    final sortedPlayers = [...state.players]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final wasSevenRolled = state.die1 + state.die2 == 7 && state.rollCount > 3;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Animated Header
                AnimatedBuilder(
                  animation: _headerController,
                  builder: (context, child) => Opacity(
                    opacity: _headerFade.value,
                    child: Transform.scale(
                      scale: _headerScale.value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        wasSevenRolled
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        size: 64,
                        color: wasSevenRolled
                            ? AppTheme.dangerRed
                            : AppTheme.successGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Round ${state.currentRound} Complete',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wasSevenRolled
                            ? 'Seven rolled! Unbanked players get 0.'
                            : 'All players stocked their points.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Leading Scorer
                if (sortedPlayers.isNotEmpty)
                  AnimatedBuilder(
                    animation: _cardsController,
                    builder: (context, child) {
                      final anim = _getCardAnimation(0, sortedPlayers.length);
                      return Transform.translate(
                        offset: Offset(
                          (1 - anim.value.clamp(0.0, 1.0)) * 100,
                          0,
                        ),
                        child: Opacity(
                          opacity: anim.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.accentGold.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFA000),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              sortedPlayers[0].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '1st',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.accentGold
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          sortedPlayers[0].currentRoundStock > 0
                              ? 'Stocked +${sortedPlayers[0].currentRoundStock} this round'
                              : 'No points this round',
                          style: TextStyle(
                            color: sortedPlayers[0].currentRoundStock > 0
                                ? AppTheme.successGreen
                                : AppTheme.dangerRed,
                          ),
                        ),
                        trailing: Text(
                          '${sortedPlayers[0].totalScore}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Other Standings
                Expanded(
                  child: AnimatedBuilder(
                    animation: _cardsController,
                    builder: (context, _) => ListView.builder(
                      itemCount: sortedPlayers.length > 1
                          ? sortedPlayers.length - 1
                          : 0,
                      itemBuilder: (context, index) {
                        final playerIndex = index + 1;
                        final player = sortedPlayers[playerIndex];
                        final cardAnim = _getCardAnimation(
                          playerIndex,
                          sortedPlayers.length,
                        );

                        return Transform.translate(
                          offset: Offset(
                            (1 - cardAnim.value.clamp(0.0, 1.0)) * 100,
                            0,
                          ),
                          child: Opacity(
                            opacity: cardAnim.value.clamp(0.0, 1.0),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${playerIndex + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  player.currentRoundStock > 0
                                      ? 'Stocked +${player.currentRoundStock} this round'
                                      : 'No points this round',
                                  style: TextStyle(
                                    color: player.currentRoundStock > 0
                                        ? AppTheme.successGreen
                                        : AppTheme.dangerRed,
                                  ),
                                ),
                                trailing: Text(
                                  '${player.totalScore}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated Action button
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _buttonSlide.value),
                    child: Opacity(
                      opacity: _buttonController.value,
                      child: child,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (state.gameOver) {
                          widget.onGameOver();
                        } else {
                          widget.onNextRound();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        state.gameOver
                            ? 'See Final Results'
                            : 'Next Round (${state.currentRound + 1} of ${state.totalRounds})',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GAME OVER VIEW
// ============================================================================

class _GameOverView extends StatefulWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _GameOverView({required this.onPlayAgain, required this.onHome});

  @override
  State<_GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<_GameOverView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final winners = game.getWinners();
    final sortedPlayers = [...game.state.players]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Winner announcement
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentGold.withOpacity(0.2),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.accentGold,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            winners.length > 1 ? 'Winners!' : 'Winner!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            winners.map((w) => w.name).join(' & '),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${winners.first.totalScore} points',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Final standings
                    Text(
                      'Final Standings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedPlayers.length,
                        itemBuilder: (context, index) {
                          final player = sortedPlayers[index];
                          final isWinner = winners.any(
                            (w) => w.id == player.id,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isWinner
                                ? AppTheme.accentGold.withOpacity(0.1)
                                : null,
                            child: ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? AppTheme.accentGold
                                      : (index == 1
                                            ? Colors.grey.shade400
                                            : (index == 2
                                                  ? Colors.brown.shade400
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: index < 3
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                '${player.totalScore}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onHome,
                            child: const Text('Home'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onPlayAgain,
                            child: const Text('Play Again'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                  AppTheme.accentGold,
                  Colors.pink,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
