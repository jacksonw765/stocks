import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Epic market crash animation shown when a 7 is rolled
class MarketCrashOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const MarketCrashOverlay({super.key, required this.onComplete});

  @override
  State<MarketCrashOverlay> createState() => _MarketCrashOverlayState();
}

class _MarketCrashOverlayState extends State<MarketCrashOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shakeController;
  late AnimationController _glitchController;
  late AnimationController _pulseController;
  late Animation<double> _crashAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _pulseAnimation;

  final List<_FallingNumber> _fallingNumbers = [];
  final List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Main animation controller - extended for more drama
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // Shake controller - more aggressive shaking
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    // Glitch effect controller
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Pulse controller for flash effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _crashAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.3), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
        ]).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.transparent,
          end: Color.fromRGBO(
            AppTheme.dangerRed.r.toInt(),
            AppTheme.dangerRed.g.toInt(),
            AppTheme.dangerRed.b.toInt(),
            0.4,
          ),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Color.fromRGBO(
            AppTheme.dangerRed.r.toInt(),
            AppTheme.dangerRed.g.toInt(),
            AppTheme.dangerRed.b.toInt(),
            0.4,
          ),
          end: Color.fromRGBO(
            AppTheme.dangerRed.r.toInt(),
            AppTheme.dangerRed.g.toInt(),
            AppTheme.dangerRed.b.toInt(),
            0.2,
          ),
        ),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Color.fromRGBO(
            AppTheme.dangerRed.r.toInt(),
            AppTheme.dangerRed.g.toInt(),
            AppTheme.dangerRed.b.toInt(),
            0.2,
          ),
          end: Colors.transparent,
        ),
        weight: 20,
      ),
    ]).animate(_mainController);

    // Chart crashing animation
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.4, curve: Curves.easeIn),
      ),
    );
    // Pulse flash effect
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(_pulseController);

    // Generate falling numbers
    for (int i = 0; i < 35; i++) {
      _fallingNumbers.add(
        _FallingNumber(
          value: _random.nextInt(9999),
          x: _random.nextDouble(),
          delay: _random.nextDouble() * 0.4,
          speed: 0.4 + _random.nextDouble() * 0.6,
          size: 16.0 + _random.nextDouble() * 16.0,
        ),
      );
    }

    // Generate explosion particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          angle: _random.nextDouble() * 2 * math.pi,
          speed: 100 + _random.nextDouble() * 300,
          size: 4 + _random.nextDouble() * 8,
          delay: _random.nextDouble() * 0.2,
        ),
      );
    }

    // Start shake with varying intensity
    _shakeController.repeat(reverse: true);

    // Start glitch effect at intervals
    _startGlitchSequence();

    // Start pulse effect at intervals
    _startPulseSequence();

    // Start main animation
    _mainController.forward().then((_) {
      _shakeController.stop();
      _glitchController.stop();
      _pulseController.stop();
      widget.onComplete();
    });
  }

  void _startGlitchSequence() async {
    // Run glitch effects at random intervals during first 50% of animation
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(300)));
      if (!mounted || _mainController.value > 0.5) break;
      _glitchController.forward(from: 0);
    }
  }

  void _startPulseSequence() async {
    // Pulse 3 times in sync with dramatic moments
    final delays = [200, 600, 1200];
    for (final delay in delays) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted || _mainController.value > 0.7) break;
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shakeController.dispose();
    _glitchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _shakeController,
        _glitchController,
        _pulseController,
      ]),
      builder: (context, child) {
        // Calculate shake intensity based on animation progress
        final shakeIntensity = _mainController.value < 0.5
            ? 15.0 * (1 - _mainController.value * 2)
            : 0.0;
        final shakeX = (_shakeController.value - 0.5) * shakeIntensity * 2;
        final shakeY =
            (math.sin(_shakeController.value * math.pi) - 0.5) * shakeIntensity;

        // Glitch offset
        final glitchOffset = _glitchController.isAnimating
            ? (_random.nextDouble() - 0.5) * 20
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeX + glitchOffset, shakeY),
          child: Stack(
            children: [
              // Red overlay with pulse
              Positioned.fill(child: Container(color: _colorAnimation.value)),

              // Flash pulse overlay
              if (_pulseController.isAnimating)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withAlpha(
                      (_pulseAnimation.value * 0.3 * 255).toInt(),
                    ),
                  ),
                ),

              // RGB Glitch effect
              if (_glitchController.isAnimating) ...[
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(-3, 0),
                    child: Container(color: Colors.red.withAlpha(26)),
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(3, 0),
                    child: Container(color: Colors.cyan.withAlpha(26)),
                  ),
                ),
              ],

              // Crashing chart line
              Positioned(
                left: 0,
                right: 0,
                top: size.height * 0.15,
                child: Opacity(
                  opacity: (1 - _mainController.value).clamp(0.0, 1.0) * 0.6,
                  child: CustomPaint(
                    size: Size(size.width, size.height * 0.4),
                    painter: _CrashingChartPainter(
                      progress: _chartAnimation.value,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                ),
              ),

              // Explosion particles
              ...(_particles.map((particle) {
                final progress =
                    ((_mainController.value - particle.delay) / 0.5).clamp(
                      0.0,
                      1.0,
                    );
                final distance = particle.speed * progress;
                final x = size.width / 2 + math.cos(particle.angle) * distance;
                final y = size.height / 2 + math.sin(particle.angle) * distance;

                return Positioned(
                  left: x - particle.size / 2,
                  top: y - particle.size / 2,
                  child: Opacity(
                    opacity: (1 - progress).clamp(0.0, 1.0),
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(
                              AppTheme.dangerRed.r.toInt(),
                              AppTheme.dangerRed.g.toInt(),
                              AppTheme.dangerRed.b.toInt(),
                              0.5,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })),

              // Falling numbers
              ..._fallingNumbers.map((num) {
                final progress =
                    (_mainController.value - num.delay).clamp(0.0, 1.0) *
                    num.speed;
                return Positioned(
                  left: num.x * size.width,
                  top: -50 + (progress * (size.height + 100)),
                  child: Opacity(
                    opacity: (1 - progress).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: progress * 0.5,
                      child: Text(
                        '-${num.value}',
                        style: TextStyle(
                          fontSize: num.size,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(
                            AppTheme.dangerRed.r.toInt(),
                            AppTheme.dangerRed.g.toInt(),
                            AppTheme.dangerRed.b.toInt(),
                            0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Center crash content
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _crashAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Added children: []
                        Material(
                          type: MaterialType.transparency,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Crash icon with glow
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.dangerRed,
                                      Color.fromRGBO(
                                        AppTheme.dangerRed.r.toInt(),
                                        AppTheme.dangerRed.g.toInt(),
                                        AppTheme.dangerRed.b.toInt(),
                                        0.8,
                                      ),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromRGBO(
                                        AppTheme.dangerRed.r.toInt(),
                                        AppTheme.dangerRed.g.toInt(),
                                        AppTheme.dangerRed.b.toInt(),
                                        0.6,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 15,
                                    ),
                                    BoxShadow(
                                      color: Color.fromRGBO(
                                        AppTheme.dangerRed.r.toInt(),
                                        AppTheme.dangerRed.g.toInt(),
                                        AppTheme.dangerRed.b.toInt(),
                                        0.3,
                                      ),
                                      blurRadius: 80,
                                      spreadRadius: 30,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.trending_down,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 28),
                              // CRASH text with shadow
                              Text(
                                'MARKET CRASH!',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.dangerRed,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Color.fromRGBO(
                                        AppTheme.dangerRed.r.toInt(),
                                        AppTheme.dangerRed.g.toInt(),
                                        AppTheme.dangerRed.b.toInt(),
                                        0.5,
                                      ),
                                      blurRadius: 20,
                                    ),
                                    const Shadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Seven rolled — Round over!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(204),
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
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for crashing stock chart line
class _CrashingChartPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CrashingChartPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Color.fromRGBO(
        color.r.toInt(),
        color.g.toInt(),
        color.b.toInt(),
        0.7,
      )
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Color.fromRGBO(
        color.r.toInt(),
        color.g.toInt(),
        color.b.toInt(),
        0.3,
      )
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();

    // Create a chart that starts high, has some ups and downs, then crashes
    final points = <Offset>[
      Offset(0, size.height * 0.3),
      Offset(size.width * 0.1, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.35),
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.4, size.height * 0.15),
      Offset(size.width * 0.5, size.height * 0.25),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.85),
      Offset(size.width, size.height * 0.95),
    ];

    // Only draw up to current progress
    final pointsToDraw = (points.length * progress).ceil();
    if (pointsToDraw < 2) return;

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < pointsToDraw; i++) {
      // Interpolate the last point based on progress
      if (i == pointsToDraw - 1) {
        final t = (progress * points.length) - (pointsToDraw - 1);
        final prev = points[i - 1];
        final curr = points[i];
        final x = prev.dx + (curr.dx - prev.dx) * t;
        final y = prev.dy + (curr.dy - prev.dy) * t;
        path.lineTo(x, y);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Draw glow first, then main line
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrashingChartPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class _FallingNumber {
  final int value;
  final double x;
  final double delay;
  final double speed;
  final double size;

  _FallingNumber({
    required this.value,
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
  });
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double delay;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
  });
}
