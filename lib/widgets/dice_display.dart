import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated dice display with visual effects
class DiceDisplay extends StatefulWidget {
  final int die1;
  final int die2;
  final bool isDoubles;
  final bool isSeven;
  final bool isSafeSeven;
  final bool showPlaceholder;

  const DiceDisplay({
    super.key,
    required this.die1,
    required this.die2,
    this.isDoubles = false,
    this.isSeven = false,
    this.isSafeSeven = false,
    this.showPlaceholder = false,
  });

  @override
  State<DiceDisplay> createState() => _DiceDisplayState();
}

class _DiceDisplayState extends State<DiceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(DiceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.die1 != widget.die1 || oldWidget.die2 != widget.die2) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getDieColor() {
    if (widget.isSafeSeven) return AppTheme.accentGold;
    if (widget.isSeven) return AppTheme.dangerRed;
    if (widget.isDoubles) return AppTheme.successGreen;
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Transform.rotate(angle: _rotateAnimation.value, child: child),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DieWidget(
            value: widget.die1,
            color: _getDieColor(),
            isSpecial: widget.isDoubles || widget.isSeven || widget.isSafeSeven,
            showPlaceholder: widget.showPlaceholder,
          ),
          const SizedBox(width: 16),
          _DieWidget(
            value: widget.die2,
            color: _getDieColor(),
            isSpecial: widget.isDoubles || widget.isSeven || widget.isSafeSeven,
            showPlaceholder: widget.showPlaceholder,
          ),
        ],
      ),
    );
  }
}

class _DieWidget extends StatelessWidget {
  final int value;
  final Color color;
  final bool isSpecial;
  final bool showPlaceholder;

  const _DieWidget({
    required this.value,
    required this.color,
    required this.isSpecial,
    this.showPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showPlaceholder) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.casino_outlined,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isSpecial
                ? color.withOpacity(0.5)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSpecial ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSpecial
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isSpecial
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
