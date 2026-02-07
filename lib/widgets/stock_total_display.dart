import 'package:flutter/material.dart';
import '../utils/game_logic.dart';
import '../theme/app_theme.dart';

/// Compact, animated stock total display
class StockTotalDisplay extends StatefulWidget {
  final int total;
  final RollOutcome? lastOutcome;
  final int rollCount;

  const StockTotalDisplay({
    super.key,
    required this.total,
    this.lastOutcome,
    required this.rollCount,
  });

  @override
  State<StockTotalDisplay> createState() => _StockTotalDisplayState();
}

class _StockTotalDisplayState extends State<StockTotalDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  int _displayedTotal = 0;

  @override
  void initState() {
    super.initState();
    _displayedTotal = widget.total;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(StockTotalDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.total != widget.total) {
      _animateChange();
    }
  }

  void _animateChange() {
    _controller.forward(from: 0).then((_) {
      setState(() => _displayedTotal = widget.total);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.lastOutcome) {
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

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final isSpecial =
        widget.lastOutcome != RollOutcome.normal && widget.lastOutcome != null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColor, bgColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(
                    0.4 + (_pulseAnimation.value * 0.2),
                  ),
                  blurRadius: 20 + (_pulseAnimation.value * 10),
                  spreadRadius: isSpecial ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main number
                Text(
                  '$_displayedTotal',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                // Roll count indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.rollCount == 0
                        ? 'Waiting for first roll'
                        : 'Roll ${widget.rollCount}${widget.rollCount <= 3 ? ' • Safe' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
