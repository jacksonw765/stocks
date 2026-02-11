import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../utils/game_logic.dart';
import '../theme/app_theme.dart';

/// Sleek animated dashboard showing current stock, roll history, and dice
class StockTotalDisplay extends StatefulWidget {
  final int total;
  final RollOutcome? lastOutcome;
  final int rollCount;
  final int? die1;
  final int? die2;

  /// Persistent roll history across all rounds
  final List<RollHistoryEntry> rollHistory;

  /// Current roller info for per-player log display
  final String? currentRollerId;
  final String? currentRollerName;

  const StockTotalDisplay({
    super.key,
    required this.total,
    this.lastOutcome,
    required this.rollCount,
    this.die1,
    this.die2,
    this.rollHistory = const [],
    this.currentRollerId,
    this.currentRollerName,
  });

  @override
  State<StockTotalDisplay> createState() => _StockTotalDisplayState();
}

class _StockTotalDisplayState extends State<StockTotalDisplay>
    with TickerProviderStateMixin {
  // Value animation
  late AnimationController _valueController;
  late AnimationController _glowController;
  late AnimationController _chipEntryController;
  late Animation<double> _glowAnimation;

  final ScrollController _scrollController = ScrollController();

  double _displayedTotal = 0;
  double _previousTotal = 0;
  int _prevHistoryLength = 0;

  @override
  void initState() {
    super.initState();
    _displayedTotal = widget.total.toDouble();
    _previousTotal = widget.total.toDouble();
    _prevHistoryLength = widget.rollHistory.length;

    _valueController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _valueController.addListener(() {
      setState(() {
        final t = Curves.easeOutCubic.transform(_valueController.value);
        _displayedTotal =
            _previousTotal + (t * (widget.total - _previousTotal));
      });
    });

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 900),
      value: 1.0,
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));
    _glowController.addListener(() => setState(() {}));

    _chipEntryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(StockTotalDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.total != widget.total) {
      _previousTotal = _displayedTotal;
      _valueController.forward(from: 0);
      _glowController.forward(from: 0);
    }

    // New roll appeared in the history
    if (widget.rollHistory.length > _prevHistoryLength) {
      _prevHistoryLength = widget.rollHistory.length;
      _chipEntryController.forward(from: 0);

      // Auto-scroll to latest chip
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _glowController.dispose();
    _chipEntryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getOutcomeColor(RollOutcome? outcome) {
    switch (outcome) {
      case RollOutcome.seven:
        return AppTheme.dangerRed;
      case RollOutcome.doubles:
        return AppTheme.successGreen;
      case RollOutcome.seven70:
        return AppTheme.accentGold;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getCurrentColor() {
    if (widget.total == 0 && widget.rollHistory.isEmpty) return Colors.grey;
    return _getOutcomeColor(widget.lastOutcome);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _getCurrentColor();
    final history = widget.rollHistory;
    final change = history.length > 1
        ? widget.total - history[history.length - 2].stockTotal
        : (history.isNotEmpty ? widget.total : 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final glowActive = _glowAnimation.value > 0.01 && history.isNotEmpty;

    // Smoothly interpolated border color — always 1px width to avoid shift
    final restBorderColor = Theme.of(context).colorScheme.outline.withAlpha(30);
    final glowBorderColor = currentColor.withAlpha(
      (80 * _glowAnimation.value).toInt(),
    );
    final borderColor = glowActive ? glowBorderColor : restBorderColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top: Roll info + Stats pills + Change ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.casino_outlined,
                  label: widget.rollCount == 0
                      ? 'Awaiting roll'
                      : 'Roll ${widget.rollCount}',
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
                const SizedBox(width: 8),
                if (widget.rollCount > 0 && widget.rollCount <= 3)
                  _buildInfoChip(
                    context,
                    icon: Icons.shield_outlined,
                    label: 'Safe Zone',
                    color: AppTheme.successGreen,
                  ),
                if (widget.rollCount > 3)
                  _buildInfoChip(
                    context,
                    icon: Icons.favorite_border_rounded,
                    label: GameLogic.getSurvivalText(widget.rollCount),
                    color: _getSurvivalColor(widget.rollCount),
                  ),
                const Spacer(),
                // Change pill
                if (change != 0 && history.isNotEmpty)
                  _buildInfoChip(
                    context,
                    icon: change > 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    label: '${change > 0 ? '+' : ''}$change',
                    color: currentColor,
                  ),
              ],
            ),
          ),

          // ── Points ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_displayedTotal.toInt()}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Dice Display (if dice values provided) ──
          if (widget.die1 != null && widget.die2 != null) ...[
            _AnimatedDicePair(
              die1: widget.die1!,
              die2: widget.die2!,
              outcome: widget.lastOutcome,
            ),
            const SizedBox(height: 12),
          ],

          // ── Roll History Scale (last 5) ──
          SizedBox(
            height: 48,
            child: history.isNotEmpty
                ? _buildRollHistoryScale(context, history)
                : _buildEmptyHistoryPlaceholder(context),
          ),

          const SizedBox(height: 8),

          // ── Per-Player Roll Log (fixed height to prevent layout jumps) ──
          SizedBox(
            height: 56,
            child: widget.currentRollerId != null
                ? _buildPlayerRollLog(context, history)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildRollHistoryScale(
    BuildContext context,
    List<RollHistoryEntry> history,
  ) {
    // Only show the last 5 rolls
    final displayHistory = history.length > 5
        ? history.sublist(history.length - 5)
        : history;
    // Find the maximum value for proportional heights
    final maxVal = displayHistory.map((e) => e.stockTotal).reduce(math.max);

    // Detect round boundaries for visual separators
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: const [0.0, 0.06, 0.94, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayHistory.length,
        itemBuilder: (context, index) {
          final entry = displayHistory[index];
          final isLast = index == displayHistory.length - 1;
          final chipColor = _getOutcomeColor(entry.outcome);

          // Show a small round separator between rounds
          final showRoundSep =
              index > 0 && entry.round != displayHistory[index - 1].round;

          // Scale chip height relative to max value
          final relativeHeight = maxVal > 0
              ? (entry.stockTotal / maxVal).clamp(0.15, 1.0)
              : 0.5;

          Widget chipContent = Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Value label on active chip
              if (isLast)
                Text(
                  '${entry.stockTotal}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: chipColor,
                  ),
                ),
              const SizedBox(height: 2),
              Container(
                width: isLast ? 28 : 18,
                height: (30 * relativeHeight).clamp(6.0, 30.0),
                decoration: BoxDecoration(
                  color: isLast ? chipColor : chipColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(isLast ? 6 : 4),
                  border: isLast
                      ? Border.all(color: chipColor.withAlpha(180), width: 1.5)
                      : null,
                  boxShadow: isLast
                      ? [
                          BoxShadow(
                            color: chipColor.withAlpha(60),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          );

          // Animate the latest chip entrance
          if (isLast) {
            chipContent = AnimatedBuilder(
              animation: _chipEntryController,
              builder: (context, child) {
                final t = Curves.elasticOut.transform(
                  _chipEntryController.value.clamp(0.0, 1.0),
                );
                return Transform.scale(
                  scale: t.clamp(0.0, 1.5),
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: _chipEntryController.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: chipContent,
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Round separator
              if (showRoundSep)
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: chipContent,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyHistoryPlaceholder(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
          ),
          const SizedBox(width: 8),
          Text(
            'Roll history appears here',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRollLog(
    BuildContext context,
    List<RollHistoryEntry> allHistory,
  ) {
    // Get this player's rolls with sequential numbering
    final allPlayerRolls = allHistory
        .where((e) => e.rollerId == widget.currentRollerId)
        .toList();

    // Take last 5, preserving order
    final recentRolls = allPlayerRolls.length > 5
        ? allPlayerRolls.sublist(allPlayerRolls.length - 5)
        : allPlayerRolls;

    final rollerName = widget.currentRollerName ?? 'Player';
    final textColor = Theme.of(context).colorScheme.onSurface;

    if (recentRolls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 13,
                  color: textColor.withAlpha(100),
                ),
                const SizedBox(width: 5),
                Text(
                  '$rollerName\'s Rolls',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textColor.withAlpha(120),
                  ),
                ),
                const Spacer(),
                Text(
                  '0 total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: textColor.withAlpha(80),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'No rolls yet',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor.withAlpha(60),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 13,
                color: textColor.withAlpha(100),
              ),
              const SizedBox(width: 5),
              Text(
                '$rollerName\'s Rolls',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textColor.withAlpha(120),
                ),
              ),
              const Spacer(),
              Text(
                '${allPlayerRolls.length} total',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor.withAlpha(80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Roll entries — compact horizontal row
          Row(
            children: recentRolls.asMap().entries.map((entry) {
              final idx = entry.key;
              final roll = entry.value;
              // Calculate this roll's sequential number for this player
              final rollNum = allPlayerRolls.indexOf(roll) + 1;
              final outcomeColor = _getOutcomeColor(roll.outcome);
              final sum = roll.die1 + roll.die2;
              return Padding(
                padding: EdgeInsets.only(left: idx > 0 ? 6 : 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: outcomeColor.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: outcomeColor.withAlpha(30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$rollNum',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textColor.withAlpha(80),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        color: textColor.withAlpha(30),
                      ),
                      Text(
                        '$sum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: outcomeColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSurvivalColor(int rollCount) {
    if (rollCount <= 3) return AppTheme.successGreen;
    final survival = GameLogic.getSurvivalProbability(rollCount);
    if (survival > 0.6) return AppTheme.successGreen;
    if (survival > 0.4) return AppTheme.accentGold;
    return AppTheme.dangerRed;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Dice Pair
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimatedDicePair extends StatefulWidget {
  final int die1;
  final int die2;
  final RollOutcome? outcome;

  const _AnimatedDicePair({
    required this.die1,
    required this.die2,
    this.outcome,
  });

  @override
  State<_AnimatedDicePair> createState() => _AnimatedDicePairState();
}

class _AnimatedDicePairState extends State<_AnimatedDicePair>
    with SingleTickerProviderStateMixin {
  late AnimationController _rollController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.12), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _rollController, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.elasticOut),
    );

    if (widget.die1 > 0) _rollController.forward();
  }

  @override
  void didUpdateWidget(_AnimatedDicePair oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.die1 != widget.die1 || oldWidget.die2 != widget.die2) {
      _rollController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.die1 <= 0) {
      // Placeholder dice
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPlaceholderDie(context),
          const SizedBox(width: 14),
          _buildPlaceholderDie(context),
        ],
      );
    }

    final isDoubles = widget.die1 == widget.die2;
    final isSeven = widget.die1 + widget.die2 == 7;

    return AnimatedBuilder(
      animation: _rollController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Transform.rotate(angle: _rotateAnimation.value, child: child),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDie(
            context,
            widget.die1,
            isDoubles: isDoubles,
            isSeven: isSeven,
            outcome: widget.outcome,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ),
          _buildDie(
            context,
            widget.die2,
            isDoubles: isDoubles,
            isSeven: isSeven,
            outcome: widget.outcome,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getDieAccentColor(
                isDoubles,
                isSeven,
                outcome: widget.outcome,
              ).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '= ${widget.die1 + widget.die2}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _getDieAccentColor(
                  isDoubles,
                  isSeven,
                  outcome: widget.outcome,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDie(
    BuildContext context,
    int value, {
    required bool isDoubles,
    required bool isSeven,
    RollOutcome? outcome,
  }) {
    final accentColor = _getDieAccentColor(
      isDoubles,
      isSeven,
      outcome: outcome,
    );
    final isSpecial = isDoubles || isSeven;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSpecial
            ? accentColor
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSpecial
              ? accentColor.withAlpha(180)
              : Theme.of(context).colorScheme.outline.withAlpha(40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSpecial
                ? accentColor.withAlpha(40)
                : Colors.black.withAlpha(10),
            blurRadius: isSpecial ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isSpecial
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderDie(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.casino_outlined,
          size: 22,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
        ),
      ),
    );
  }

  Color _getDieAccentColor(
    bool isDoubles,
    bool isSeven, {
    RollOutcome? outcome,
  }) {
    if (isSeven && outcome == RollOutcome.seven70) return AppTheme.accentGold;
    if (isSeven) return AppTheme.dangerRed;
    if (isDoubles) return AppTheme.successGreen;
    return Colors.grey;
  }
}
