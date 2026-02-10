import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/game_logic.dart';
import '../theme/app_theme.dart';

/// Robinhood-style stock ticker display with animated line chart
class StockTotalDisplay extends StatefulWidget {
  final int total;
  final RollOutcome? lastOutcome;
  final int rollCount;
  final int? die1;
  final int? die2;

  const StockTotalDisplay({
    super.key,
    required this.total,
    this.lastOutcome,
    required this.rollCount,
    this.die1,
    this.die2,
  });

  @override
  State<StockTotalDisplay> createState() => _StockTotalDisplayState();
}

class _StockTotalDisplayState extends State<StockTotalDisplay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  late Animation<double> _valueAnimation;
  late Animation<double> _glowAnimation;

  // History of stock values for the chart
  final List<double> _stockHistory = [0];
  double _displayedTotal = 0;
  double _previousTotal = 0;

  @override
  void initState() {
    super.initState();
    _displayedTotal = widget.total.toDouble();
    _previousTotal = widget.total.toDouble();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _valueAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.addListener(() {
      setState(() {
        _displayedTotal =
            _previousTotal +
            (_valueAnimation.value * (widget.total - _previousTotal));
      });
    });

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));
    _glowController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(StockTotalDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.total != widget.total) {
      _previousTotal = _displayedTotal;

      // Add a new point with its final value — fl_chart will animate the transition
      _stockHistory.add(widget.total.toDouble());

      // Keep max 20 data points for chart
      if (_stockHistory.length > 20) {
        _stockHistory.removeAt(0);
      }
      _controller.forward(from: 0);
      _glowController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _getChartColor() {
    if (widget.total == 0) return Colors.grey;

    switch (widget.lastOutcome) {
      case RollOutcome.seven:
        return AppTheme.dangerRed;
      case RollOutcome.doubles:
        return AppTheme.successGreen;
      case RollOutcome.seven70:
        return AppTheme.accentGold;
      default:
        return AppTheme.successGreen; // Default to green for positive
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartColor = _getChartColor();
    final change = _stockHistory.length > 1
        ? widget.total - _stockHistory[_stockHistory.length - 2]
        : widget.total.toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _glowAnimation.value > 0
              ? chartColor.withAlpha((100 * (1 - _glowAnimation.value)).toInt())
              : Theme.of(context).colorScheme.outline.withAlpha(51),
          width: _glowAnimation.value > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _glowAnimation.value > 0
                ? chartColor.withAlpha(
                    (40 * (1 - _glowAnimation.value)).toInt(),
                  )
                : Colors.black.withAlpha(13),
            blurRadius: _glowAnimation.value > 0 ? 15 : 10,
            spreadRadius: _glowAnimation.value > 0 ? 2 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Points counter on left, change badge on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Stock value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STOCK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_displayedTotal.toInt()}',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'pts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right side: Change indicator
              if (change != 0 && _stockHistory.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chartColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: chartColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change > 0 ? '+' : ''}${change.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: chartColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Chart area
          SizedBox(
            height: 80,
            child: _stockHistory.length > 1
                ? _buildChart(chartColor)
                : _buildEmptyChart(context),
          ),

          const SizedBox(height: 8),

          // Bottom row: Roll info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.casino_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.rollCount == 0
                      ? 'Waiting for first roll'
                      : 'Roll ${widget.rollCount}${widget.rollCount <= 3 ? ' • Safe Zone' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Color lineColor) {
    // Build spots using final values — fl_chart animates the transition
    final spots = <FlSpot>[];
    for (int i = 0; i < _stockHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), _stockHistory[i]));
    }

    // Calculate bounds from actual history values
    final maxY = _stockHistory.reduce((a, b) => a > b ? a : b) * 1.1;
    final minY = _stockHistory.reduce((a, b) => a < b ? a : b) * 0.9;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_stockHistory.length - 1).toDouble(),
        minY: minY < 0 ? minY : 0,
        maxY: maxY < 10 ? 10 : maxY,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.45,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Only show dot on last point
                if (index == spots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lineColor.withAlpha(77), lineColor.withAlpha(0)],
              ),
            ),
          ),
        ],
      ),
      // Let fl_chart smoothly interpolate the entire chart (axis rescaling + line movement)
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
            const SizedBox(width: 8),
            Text(
              'Chart builds as you roll',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
