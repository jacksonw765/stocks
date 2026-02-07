import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rules screen - explains how to play
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick reference card
          Card(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppTheme.accentGold),
                      const SizedBox(width: 8),
                      const Text(
                        'Quick Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Roll dice to build a shared stock pool. Call "Stock!" anytime to lock in those points. But beware — roll a 7 after the first 3 rolls and everyone who hasn\'t stocked gets nothing!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _RuleSection(
            title: 'Object of the Game',
            icon: Icons.emoji_events,
            content:
                'Be the player who stocks the most total points across all rounds. Games are played over 10, 15, or 20 rounds.',
          ),

          _RuleSection(
            title: 'How a Round Works',
            icon: Icons.refresh,
            content:
                'Players take turns rolling two dice. The sum is added to a shared "Stock" total. At any time, any player can call "Stock!" to lock in the current total as their score for that round.',
          ),

          _RuleSection(
            title: 'First 3 Rolls (Special Rules)',
            icon: Icons.shield,
            children: [
              _RuleItem(
                '7 = +70 points',
                'Rolling a 7 in the first 3 rolls adds 70 points to the stock instead of ending the round.',
                color: AppTheme.accentGold,
              ),
              _RuleItem(
                'Doubles = Face value only',
                'Doubles during the first 3 rolls only add face value (e.g., 4+4 = 8 points).',
                color: AppTheme.secondaryColor,
              ),
            ],
          ),

          _RuleSection(
            title: 'After Roll 3 (Normal Rules)',
            icon: Icons.warning_amber,
            children: [
              _RuleItem(
                '7 = Round Ends!',
                'Rolling a 7 ends the round immediately. All players who haven\'t stocked get 0 points.',
                color: AppTheme.dangerRed,
              ),
              _RuleItem(
                'Doubles = DOUBLE the Stock!',
                'Doubles multiply the entire stock total by 2. This is when the game gets exciting!',
                color: AppTheme.successGreen,
              ),
              _RuleItem(
                'Other rolls',
                'Any other roll adds the sum to the stock total.',
                color: Colors.grey,
              ),
            ],
          ),

          _RuleSection(
            title: 'Stocking Your Points',
            icon: Icons.savings,
            content:
                'At any point during a round, call "Stock!" to lock in the current stock total as your score. Once you stock, you sit out for the rest of that round. There\'s no limit to how many players can stock on the same roll.',
          ),

          _RuleSection(
            title: 'Strategy Tips',
            icon: Icons.psychology,
            children: [
              _RuleItem(
                'Early stocking is safe',
                'But yields lower scores. Great if you\'re in the lead.',
                color: AppTheme.primaryColor,
              ),
              _RuleItem(
                'Late stocking is risky',
                'But can pay off big when doubles hit!',
                color: AppTheme.secondaryColor,
              ),
              _RuleItem(
                'Watch the stock total',
                'If it\'s already high, doubles could make it huge!',
                color: AppTheme.accentGold,
              ),
            ],
          ),

          _RuleSection(
            title: 'Variant: One Stock Per Roll',
            icon: Icons.speed,
            content:
                'A popular house rule: only one player may stock per roll. The first person to tap "Stock" after a roll gets to lock in; everyone else must wait until the next roll. Enable this in Settings.',
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? content;
  final List<Widget>? children;

  const _RuleSection({
    required this.title,
    required this.icon,
    this.content,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (content != null)
                Text(
                  content!,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              if (children != null) ...children!,
            ],
          ),
        ),
      ],
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _RuleItem(this.title, this.description, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
