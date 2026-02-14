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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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

                      // Leading Scorer
                      if (sortedPlayers.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFF8E1),
                                Color(0xFFFFECB3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFCA28),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
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
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'LEADING SCORER',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE65100),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sortedPlayers[0].name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sortedPlayers[0].currentRoundStock > 0
                                          ? 'Stocked +${sortedPlayers[0].currentRoundStock} this round'
                                          : 'No points this round',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: sortedPlayers[0].currentRoundStock > 0
                                            ? const Color(0xFF2E7D32)
                                            : AppTheme.dangerRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${sortedPlayers[0].totalScore}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                  const Text(
                                    'pts',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF795548),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Other Standings
                      for (int index = 1; index < sortedPlayers.length; index++)
                        Card(
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
                              sortedPlayers[index].name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              sortedPlayers[index].currentRoundStock > 0
                                  ? 'Stocked +${sortedPlayers[index].currentRoundStock} this round'
                                  : 'No points this round',
                              style: TextStyle(
                                color: sortedPlayers[index].currentRoundStock > 0
                                    ? AppTheme.successGreen
                                    : AppTheme.dangerRed,
                              ),
                            ),
                            trailing: Text(
                              '${sortedPlayers[index].totalScore}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action button - always visible at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
