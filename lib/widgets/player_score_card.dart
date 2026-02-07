import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

/// Player score card with animations
class PlayerScoreCard extends StatefulWidget {
  final Player player;
  final int stockTotal;
  final int leadScore;
  final bool isCurrentRoller;
  final VoidCallback onStock;

  const PlayerScoreCard({
    super.key,
    required this.player,
    required this.stockTotal,
    required this.leadScore,
    required this.isCurrentRoller,
    required this.onStock,
  });

  @override
  State<PlayerScoreCard> createState() => _PlayerScoreCardState();
}

class _PlayerScoreCardState extends State<PlayerScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isCurrentRoller) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlayerScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentRoller && !oldWidget.isCurrentRoller) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCurrentRoller && oldWidget.isCurrentRoller) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasStocked = widget.player.hasStockedThisRound;
    final isLeader =
        widget.player.totalScore == widget.leadScore && widget.leadScore > 0;
    final pointsToLead = widget.leadScore - widget.player.totalScore;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: widget.isCurrentRoller
                ? Border.all(
                    color: AppTheme.primaryColor.withOpacity(
                      0.5 + (_glowAnimation.value * 0.5),
                    ),
                    width: 2,
                  )
                : null,
            boxShadow: widget.isCurrentRoller
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(
                        0.2 * _glowAnimation.value,
                      ),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        color: hasStocked
            ? AppTheme.successGreen.withOpacity(0.1)
            : (isLeader ? AppTheme.accentGold.withOpacity(0.1) : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Player avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasStocked
                        ? [
                            AppTheme.successGreen,
                            AppTheme.successGreen.withOpacity(0.7),
                          ]
                        : (widget.isCurrentRoller
                              ? [AppTheme.primaryColor, AppTheme.secondaryColor]
                              : [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                ]),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: hasStocked
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : Text(
                          widget.player.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.isCurrentRoller
                                ? Colors.white
                                : Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.player.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isLeader) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppTheme.accentGold,
                          ),
                        ],
                        if (widget.isCurrentRoller) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ROLLING',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasStocked
                          ? 'Stocked ${widget.player.currentRoundStock} pts'
                          : (pointsToLead > 0
                                ? 'Need $pointsToLead to lead'
                                : 'Leading'),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasStocked
                            ? AppTheme.successGreen
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Score and action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.player.totalScore}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Stock button
              AnimatedOpacity(
                opacity: hasStocked ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: hasStocked ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: widget.stockTotal > 0
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: hasStocked || widget.stockTotal == 0
                          ? null
                          : widget.onStock,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          'STOCK',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.stockTotal > 0
                                ? Colors.white
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
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
