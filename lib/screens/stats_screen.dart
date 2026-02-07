import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Statistics screen - displays simulation-based game probabilities and strategy
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero card with key insight
          _HeroCard(),
          const SizedBox(height: 16),

          // Core Probabilities
          _StatsSection(
            title: 'Core Probabilities',
            icon: Icons.casino_outlined,
            initiallyExpanded: true,
            children: [
              _StatRow(
                label: 'Rolling a 7',
                value: '16.67%',
                subtext: '1 in 6 rolls',
                color: AppTheme.dangerRed,
              ),
              _StatRow(
                label: 'Rolling Doubles',
                value: '16.67%',
                subtext: '1 in 6 rolls',
                color: AppTheme.successGreen,
              ),
              _StatRow(
                label: 'Normal Roll',
                value: '66.67%',
                subtext: '2 in 3 rolls',
                color: AppTheme.secondaryColor,
              ),
              const Divider(height: 24),
              _InfoBox(
                icon: Icons.lightbulb_outline,
                text:
                    'A seven and doubles are equally likely at 1-in-6 each. After roll 3, every roll has a 16.67% chance to end the round OR double your stock.',
              ),
            ],
          ),

          // Round Survival & Growth
          _StatsSection(
            title: 'Round Survival & Growth',
            icon: Icons.timeline_outlined,
            children: [
              _StatGrid(
                stats: [
                  _GridStat('Avg Rolls/Round', '9.0'),
                  _GridStat('Median Rolls', '7'),
                  _GridStat('50% Bust By', 'Roll 7'),
                  _GridStat('75% Bust By', 'Roll 10'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Survival Probability by Roll',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _SurvivalTable(),
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.trending_up,
                text:
                    'Mean bank is MUCH higher than median because doubles create massive outliers. The median is more useful for strategy.',
              ),
            ],
          ),

          // Banking Strategy Guide
          _StatsSection(
            title: 'Banking Strategy Guide',
            icon: Icons.savings_outlined,
            children: [
              _StrategyCard(
                title: 'Conservative (30-50)',
                description: 'Safe play. Best when leading.',
                avgPoints: '48-52 pts/round',
                bustRate: '14-27%',
                color: AppTheme.successGreen,
              ),
              _StrategyCard(
                title: 'Moderate (60-80)',
                description: 'Balanced. Good default strategy.',
                avgPoints: '53-61 pts/round',
                bustRate: '31-37%',
                color: AppTheme.accentGold,
              ),
              _StrategyCard(
                title: 'Aggressive (100-150)',
                description: 'High risk. Best when behind.',
                avgPoints: '66-70 pts/round',
                bustRate: '52-64%',
                color: Colors.orange,
              ),
              _StrategyCard(
                title: 'Ultra Aggressive (200+)',
                description: 'Hail Mary. Last resort.',
                avgPoints: '73+ pts/round',
                bustRate: '73%+',
                color: AppTheme.dangerRed,
              ),
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.psychology,
                text:
                    'Sweet spot: 75-150 range captures most gains without extreme bust rates. Diminishing returns above 150.',
              ),
            ],
          ),

          // Risk-Reward Analysis
          _StatsSection(
            title: 'Risk-Reward Analysis',
            icon: Icons.balance_outlined,
            children: [
              const Text(
                'The EV Paradox',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mathematically, the expected value of waiting is always positive (+4.67 pts). So why bank at all?',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              _RiskTable(),
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.warning_amber,
                text:
                    'Banking is about RISK MANAGEMENT, not expected value. The median outcome is worse than the mean due to doubling variance.',
              ),
            ],
          ),

          // Fun Facts & Insights
          _StatsSection(
            title: 'Fun Facts & Insights',
            icon: Icons.auto_awesome_outlined,
            children: [
              _FunFact(
                icon: Icons.casino,
                title: 'Doubles Before Seven?',
                value: '50.05%',
                description: 'Essentially a coin flip!',
              ),
              _FunFact(
                icon: Icons.rocket_launch,
                title: 'Avg Peak WITH Doubles',
                value: '3,215 pts',
                description: 'vs 66.5 pts without. 48× higher!',
              ),
              _FunFact(
                icon: Icons.timer_outlined,
                title: 'First 3 Rolls',
                value: '+17.4 pts avg',
                description: 'Per roll (includes +70 sevens)',
              ),
              _FunFact(
                icon: Icons.people_outline,
                title: '10+ Players',
                value: '<1 roll each',
                description: 'Game becomes purely about timing your Stock call',
              ),
              const SizedBox(height: 8),
              _InfoBox(
                icon: Icons.stars,
                text:
                    'Reaching 500 pts from 20 requires multiple doubles — only 6.7% chance. But from 100? It jumps to 17.4%!',
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ============================================================================
// HERO CARD
// ============================================================================

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Monte Carlo Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Based on 3M+ simulated rounds. Use these probabilities to make smarter banking decisions!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATS SECTION (Expansion Tile)
// ============================================================================

class _StatsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _StatsSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }
}

// ============================================================================
// STAT COMPONENTS
// ============================================================================

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<_GridStat> stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats
          .map(
            (stat) => Container(
              width: (MediaQuery.of(context).size.width - 80) / 2,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    stat.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GridStat {
  final String label;
  final String value;
  _GridStat(this.label, this.value);
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ============================================================================
// STRATEGY CARD
// ============================================================================

class _StrategyCard extends StatelessWidget {
  final String title;
  final String description;
  final String avgPoints;
  final String bustRate;
  final Color color;

  const _StrategyCard({
    required this.title,
    required this.description,
    required this.avgPoints,
    required this.bustRate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(label: 'Avg', value: avgPoints),
              const SizedBox(width: 16),
              _MiniStat(label: 'Bust', value: bustRate),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ============================================================================
// TABLES
// ============================================================================

class _SurvivalTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [
      ('Roll 4', '83.3%', AppTheme.successGreen),
      ('Roll 5', '69.4%', AppTheme.successGreen),
      ('Roll 6', '57.9%', AppTheme.accentGold),
      ('Roll 7', '48.2%', Colors.orange),
      ('Roll 10', '27.9%', AppTheme.dangerRed),
    ];

    return Column(
      children: data.map((row) {
        final (roll, survival, color) = row;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 60, child: Text(roll)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: double.parse(survival.replaceAll('%', '')) / 100,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  survival,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RiskTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [
      ('30', '5.0', AppTheme.successGreen),
      ('50', '8.3', AppTheme.accentGold),
      ('100', '16.7', Colors.orange),
      ('200', '33.3', AppTheme.dangerRed),
      ('500', '83.3', AppTheme.dangerRed),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'Stock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Bust Cost (Stock × 16.67%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...data.map((row) {
          final (stock, bustCost, color) = row;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    stock,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(
                        '$bustCost pts expected loss',
                        style: TextStyle(color: color, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// FUN FACT
// ============================================================================

class _FunFact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;

  const _FunFact({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.secondaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
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
