import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Two-die input number pad for entering dice rolls
class NumberPad extends StatefulWidget {
  final Function(int die1, int die2) onRollEntered;

  const NumberPad({super.key, required this.onRollEntered});

  @override
  State<NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<NumberPad> {
  int? _die1;

  void _onDieTap(int value) {
    if (_die1 == null) {
      setState(() => _die1 = value);
    } else {
      widget.onRollEntered(_die1!, value);
      setState(() => _die1 = null);
    }
  }

  void _reset() {
    setState(() => _die1 = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dice preview
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DicePreview(
                  value: _die1,
                  label: 'Die 1',
                  isActive: _die1 == null,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.add, size: 24),
                const SizedBox(width: 16),
                _DicePreview(
                  value: _die1 != null ? null : null,
                  label: 'Die 2',
                  isActive: _die1 != null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _die1 == null ? 'Tap first die value' : 'Tap second die value',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            // Number buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final value = index + 1;
                return _DieButton(
                  value: value,
                  onTap: () => _onDieTap(value),
                  isFirstDie: _die1 == null,
                );
              }),
            ),
            // Always reserve space for reset button to prevent height changes
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: _die1 != null
                  ? TextButton(onPressed: _reset, child: const Text('Reset'))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DicePreview extends StatelessWidget {
  final int? value;
  final String label;
  final bool isActive;

  const _DicePreview({
    required this.value,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: value != null
            ? AppTheme.primaryColor
            : (isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: value != null
            ? Text(
                '$value',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : Text(
                '?',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
      ),
    );
  }
}

class _DieButton extends StatelessWidget {
  final int value;
  final VoidCallback onTap;
  final bool isFirstDie;

  const _DieButton({
    required this.value,
    required this.onTap,
    required this.isFirstDie,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
