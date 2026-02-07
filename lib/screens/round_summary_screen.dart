import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// Round summary screen - shown at the end of each round
class RoundSummaryScreen extends StatelessWidget {
  const RoundSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final state = game.state;

    // Sort players by total score
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
                // Header
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
                const SizedBox(height: 24),

                // Standings
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      final player = sortedPlayers[index];
                      final isLeader = index == 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: isLeader
                            ? AppTheme.accentGold.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isLeader
                                  ? AppTheme.accentGold
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isLeader
                                  ? const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      '#${index + 1}',
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (state.gameOver) {
                        Navigator.pushReplacementNamed(context, '/game-over');
                      } else {
                        game.startNextRound();
                        Navigator.pop(context);
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
