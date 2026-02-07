import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/game_logic.dart';
import '../widgets/stock_total_display.dart';
import '../widgets/number_pad.dart';
import '../widgets/player_score_card.dart';
import '../widgets/dice_display.dart';
import '../theme/app_theme.dart';

/// Main game screen - where all the action happens
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isKeypadVisible = true;

  void _showStockConfirmation(
    BuildContext context,
    String playerId,
    String playerName,
    int stockTotal,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<GameProvider>().stockPlayer(playerId);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm Stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final state = game.state;

        // Navigate to round summary when round ends
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!state.roundActive) {
            Navigator.pushNamed(context, '/round-summary');
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text('Round ${state.currentRound} of ${state.totalRounds}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => Navigator.pushNamed(context, '/rules'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Current roller banner
              if (state.currentRoller != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: AppTheme.primaryColor.withOpacity(0.1),
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
              ),

              const SizedBox(height: 12),

              // Dice display
              if (state.die1 > 0 && state.die2 > 0) ...[
                DiceDisplay(
                  die1: state.die1,
                  die2: state.die2,
                  isDoubles: state.die1 == state.die2,
                  isSeven: state.die1 + state.die2 == 7,
                ),
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
                  padding: const EdgeInsets.only(bottom: 8),
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

              // Number pad / Restore button
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.bottomCenter,
                child: _isKeypadVisible
                    ? NumberPad(
                        onRollEntered: (die1, die2) {
                          game.enterRoll(die1, die2);
                        },
                        onMinimize: () =>
                            setState(() => _isKeypadVisible = false),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: SafeArea(
                          top: false,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _isKeypadVisible = true),
                            icon: const Icon(Icons.keyboard_arrow_up),
                            label: const Text('Show Keypad'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
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

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
