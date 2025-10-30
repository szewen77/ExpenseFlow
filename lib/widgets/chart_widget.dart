import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/category_visuals.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget._({
    required this.height,
    required this.hasData,
    required this.child,
    super.key,
  });

  factory ChartWidget.pie({
    Key? key,
    required Map<String, double> data,
    double height = 220,
    List<Color>? colors,
  }) {
    return ChartWidget._(
      key: key,
      height: height,
      hasData: data.values.any((value) => value > 0),
      child: _PieChartContent(data: data, colors: colors),
    );
  }

  factory ChartWidget.bar({
    Key? key,
    required Map<String, double> data,
    double height = 240,
    List<Color>? colors,
  }) {
    return ChartWidget._(
      key: key,
      height: height,
      hasData: data.values.any((value) => value > 0),
      child: _BarChartContent(data: data, colors: colors),
    );
  }

  factory ChartWidget.line({
    Key? key,
    required List<FlSpot> spots,
    double height = 260,
    double? minY,
    double? maxY,
  }) {
    return ChartWidget._(
      key: key,
      height: height,
      hasData: spots.isNotEmpty,
      child: _LineChartContent(spots: spots, minY: minY, maxY: maxY),
    );
  }

  final double height;
  final bool hasData;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data to display yet',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizedBox(height: height, child: child),
    );
  }
}

class _PieChartContent extends StatefulWidget {
  const _PieChartContent({required this.data, this.colors});

  final Map<String, double> data;
  final List<Color>? colors;

  @override
  State<_PieChartContent> createState() => _PieChartContentState();
}

class _PieChartContentState extends State<_PieChartContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _defaultColors = <Color>[
    Color(0xFF2A9D8F), // teal
    Color(0xFFE9C46A), // yellow
    Color(0xFF8A5CF6), // purple (slightly warmer)
    Color(0xFF2F80ED), // blue
    Color(0xFFEF4444), // red
    Color(0xFF26A69A), // teal variant
    Color(0xFFF4A261), // orange accent
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.where((entry) => entry.value > 0).toList();
    final palette = widget.colors ?? _defaultColors;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 32,
            startDegreeOffset: -90,
            sections: [
              for (var i = 0; i < entries.length; i++)
                PieChartSectionData(
                  color: palette[i % palette.length],
                  value: entries[i].value * _animation.value,
                  title:
                      '${entries[i].key}\n${entries[i].value.toStringAsFixed(0)}',
                  titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(_animation.value),
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 80 * _animation.value,
                  badgeWidget: Opacity(
                    opacity: _animation.value,
                    child: _CategoryBadge(category: entries[i].key),
                  ),
                  badgePositionPercentageOffset: 1.2,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BarChartContent extends StatefulWidget {
  const _BarChartContent({required this.data, this.colors});

  final Map<String, double> data;
  final List<Color>? colors;

  @override
  State<_BarChartContent> createState() => _BarChartContentState();
}

class _BarChartContentState extends State<_BarChartContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _defaultColors = <Color>[
    Color(0xFF2A9D8F), // teal
    Color(0xFFE9C46A), // yellow
    Color(0xFF8A5CF6), // purple
    Color(0xFF2F80ED), // blue
    Color(0xFFEF4444), // red
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.where((entry) => entry.value > 0).toList();
    final palette = widget.colors ?? _defaultColors;

    final maxY = entries.fold<double>(
      0,
      (previous, entry) => math.max(previous, entry.value),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final groups = <BarChartGroupData>[];
        final labels = <int, String>{};

        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          groups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entry.value * _animation.value,
                  color: palette[i % palette.length],
                  borderRadius: BorderRadius.circular(8),
                  width: 18,
                ),
              ],
            ),
          );
          labels[i] = entry.key;
        }

        return Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: BarChart(
            BarChartData(
              barGroups: groups,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxY > 0 ? math.max(maxY / 4, 1.0) : 1.0,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final label = labels[value.toInt()] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = labels[group.x.toInt()] ?? '';
                    return BarTooltipItem(
                      '$label\n${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LineChartContent extends StatefulWidget {
  const _LineChartContent({required this.spots, this.minY, this.maxY});

  final List<FlSpot> spots;
  final double? minY;
  final double? maxY;

  @override
  State<_LineChartContent> createState() => _LineChartContentState();
}

class _LineChartContentState extends State<_LineChartContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xs = widget.spots.map((spot) => spot.x).toList();
    final ys = widget.spots.map((spot) => spot.y).toList();

    final effectiveMinX = xs.reduce(math.min);
    final effectiveMaxX = xs.reduce(math.max);
    final effectiveMinY = widget.minY ?? math.min(0, ys.reduce(math.min));
    final effectiveMaxY = widget.maxY ?? ys.reduce(math.max);
    final rangeY = (effectiveMaxY - effectiveMinY).abs();
    final paddingY = rangeY == 0
        ? (effectiveMaxY == 0 ? 1.0 : effectiveMaxY.abs() * 0.1)
        : rangeY * 0.1;
    final maxYValue = effectiveMaxY + paddingY;
    final double horizontalInterval = rangeY == 0
        ? (effectiveMaxY == 0 ? 1.0 : effectiveMaxY.abs())
        : rangeY / 4;

    final double intervalX = math.max(
      1.0,
      ((effectiveMaxX - effectiveMinX) / 5).ceilToDouble(),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate which spots to show based on animation progress
        final visibleSpotCount = (widget.spots.length * _animation.value).ceil();
        final visibleSpots = widget.spots.take(visibleSpotCount).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LineChart(
            LineChartData(
              minX: effectiveMinX,
              maxX: effectiveMaxX,
              minY: effectiveMinY,
              maxY: maxYValue,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: intervalX,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: horizontalInterval,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(
                show: true,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: visibleSpots.isEmpty ? [FlSpot(effectiveMinX, 0)] : visibleSpots,
                  isCurved: true,
                  color: const Color(0xFF2A9D8F),
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A9D8F).withValues(alpha: 0.18)
                        : const Color(0xFF2A9D8F).withValues(alpha: 0.12),
                  ),
                  barWidth: 3,
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (items) {
                    return items
                        .map(
                          (spot) => LineTooltipItem(
                            '${spot.x.toInt()} : ${spot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white),
                          ),
                        )
                        .toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisuals[category] ?? categoryVisuals['Other']!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Icon(
          visual.icon,
          size: 14,
          color: visual.color ?? const Color(0xFF2A9D8F),
        ),
      ),
    );
  }
}
