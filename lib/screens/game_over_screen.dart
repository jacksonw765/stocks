import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// Game over screen - winner celebration and final standings
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
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
                            decoration: BoxDecoration(
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
                            style: TextStyle(
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
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                            child: const Text('Home'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              game.playAgain();
                              Navigator.pushReplacementNamed(context, '/game');
                            },
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
