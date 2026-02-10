import 'package:flutter/material.dart';

/// Two-die input number pad for entering dice rolls
class NumberPad extends StatefulWidget {
  final Function(int die1, int die2) onRollEntered;
  final Function(int? pendingDie)? onPendingDieChanged;
  final VoidCallback? onMinimize;

  const NumberPad({
    super.key,
    required this.onRollEntered,
    this.onPendingDieChanged,
    this.onMinimize,
  });

  @override
  State<NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<NumberPad> {
  int? _die1;

  void _onDieTap(int value) {
    if (_die1 == null) {
      setState(() => _die1 = value);
      widget.onPendingDieChanged?.call(value);
    } else {
      widget.onRollEntered(_die1!, value);
      setState(() => _die1 = null);
      widget.onPendingDieChanged?.call(null);
    }
  }

  void _reset() {
    setState(() => _die1 = null);
    widget.onPendingDieChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimize handle
          GestureDetector(
            onTap: widget.onMinimize,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Number buttons - two rows
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final value = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _DieButton(
                  value: value,
                  onTap: () => _onDieTap(value),
                  isSelected: _die1 == value,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final value = index + 4;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _DieButton(
                  value: value,
                  onTap: () => _onDieTap(value),
                  isSelected: _die1 == value,
                ),
              );
            }),
          ),
          // Compact reset button (only shows when die1 is selected)
          if (_die1 != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _DieButton extends StatefulWidget {
  final int value;
  final VoidCallback onTap;
  final bool isSelected;

  const _DieButton({
    required this.value,
    required this.onTap,
    required this.isSelected,
  });

  @override
  State<_DieButton> createState() => _DieButtonState();
}

class _DieButtonState extends State<_DieButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withAlpha(40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary.withAlpha(60)
                    : Colors.black.withAlpha(15),
                blurRadius: widget.isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.value}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
