import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Home screen - main menu and landing page
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) =>
                        Transform.scale(scale: _logoScale.value, child: child),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 55,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title with gradient
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'STOCKS',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Text(
                      'Roll · Risk · Win',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Round selector with animated indicator
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) => _AnimatedRoundSelector(
                        rounds: const [5, 10, 15, 20, 25],
                        selectedRounds: settings.totalRounds,
                        onSelected: settings.setTotalRounds,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Primary action button - New Game
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/game'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'New Game',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Secondary buttons
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.analytics_outlined,
                            label: 'Stats',
                            onTap: () => Navigator.pushNamed(context, '/stats'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.help_outline_rounded,
                            label: 'Rules',
                            onTap: () => Navigator.pushNamed(context, '/rules'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.tune_rounded,
                            label: 'Settings',
                            onTap: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated round selector with sliding indicator and bounce effect
class _AnimatedRoundSelector extends StatefulWidget {
  final List<int> rounds;
  final int selectedRounds;
  final ValueChanged<int> onSelected;

  const _AnimatedRoundSelector({
    required this.rounds,
    required this.selectedRounds,
    required this.onSelected,
  });

  @override
  State<_AnimatedRoundSelector> createState() => _AnimatedRoundSelectorState();
}

class _AnimatedRoundSelectorState extends State<_AnimatedRoundSelector>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  int? _bouncingIndex;

  static const double _itemWidth = 52.0;
  static const double _itemHeight = 44.0;
  static const double _padding = 4.0;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  int get _selectedIndex => widget.rounds.indexOf(widget.selectedRounds);

  void _onTap(int index) {
    if (widget.rounds[index] == widget.selectedRounds) return;

    setState(() => _bouncingIndex = index);
    _bounceController.forward(from: 0).then((_) {
      setState(() => _bouncingIndex = null);
    });

    widget.onSelected(widget.rounds[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'NUMBER OF ROUNDS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Sliding indicator background
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: _selectedIndex * _itemWidth,
                    top: 0,
                    child: Container(
                      width: _itemWidth,
                      height: _itemHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(
                              _glowAnimation.value,
                            ),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Round buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.rounds.length, (index) {
                  final rounds = widget.rounds[index];
                  final isSelected = rounds == widget.selectedRounds;
                  final isBouncing = index == _bouncingIndex;

                  return GestureDetector(
                    onTap: () => _onTap(index),
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        final scale = isBouncing ? _bounceAnimation.value : 1.0;
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: _itemWidth,
                        height: _itemHeight,
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          child: Text('$rounds'),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
