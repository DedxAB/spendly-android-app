import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/insights/domain/entities/expense_slice.dart';
import 'package:spendly/features/insights/domain/entities/insight_point.dart';
import 'package:spendly/features/insights/presentation/providers/insights_provider.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final distribution = ref.watch(expenseDistributionProvider);
    final trend = ref.watch(dailyTrendProvider);
    final compare = ref.watch(incomeVsExpenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          24,
        ),
        children: [
          _SectionTitle('Expense Distribution'),
          Card(
            child: SizedBox(
              height: 280,
              child: distribution.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No expense data'));
                  }
                  return _ExpenseDonutCard(
                    slices: items,
                    touchedIndex: _touchedPieIndex,
                    onTouchIndexChanged: (value) {
                      setState(() => _touchedPieIndex = value);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Daily Spending Trend'),
          Card(
            child: SizedBox(
              height: 300,
              child: trend.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No trend data'));
                  }
                  return _ModernTrendChart(points: items, isDark: isDark);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Income vs Expense'),
          Card(
            child: SizedBox(
              height: 250,
              child: compare.when(
                data: (map) {
                  final income = map['income'] ?? 0;
                  final expense = map['expense'] ?? 0;
                  return _IncomeExpenseBars(
                    income: income,
                    expense: expense,
                    isDark: isDark,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDonutCard extends StatelessWidget {
  const _ExpenseDonutCard({
    required this.slices,
    required this.touchedIndex,
    required this.onTouchIndexChanged,
  });

  final List<ExpenseSlice> slices;
  final int touchedIndex;
  final ValueChanged<int> onTouchIndexChanged;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, item) => sum + item.total);
    final selected = touchedIndex >= 0 && touchedIndex < slices.length
        ? slices[touchedIndex]
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          onTouchIndexChanged(-1);
                          return;
                        }
                        onTouchIndexChanged(
                          response!.touchedSection!.touchedSectionIndex,
                        );
                      },
                    ),
                    sections: [
                      for (var i = 0; i < slices.length; i++)
                        PieChartSectionData(
                          value: slices[i].total,
                          color: Formatters.parseHexColor(slices[i].color),
                          radius: i == touchedIndex ? 70 : 62,
                          title: '',
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.currency(selected?.total ?? total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected?.category ?? 'Total Expense',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: slices
                .take(6)
                .map((slice) {
                  final percent = total == 0 ? 0 : (slice.total / total) * 100;
                  return _LegendChip(
                    color: Formatters.parseHexColor(slice.color),
                    label: '${slice.category} ${percent.toStringAsFixed(0)}%',
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ModernTrendChart extends StatelessWidget {
  const _ModernTrendChart({required this.points, required this.isDark});

  final List<InsightPoint> points;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final weekPoints = points.length > 7
        ? points.sublist(points.length - 7)
        : points;
    final maxY = weekPoints.map((e) => e.value).fold<double>(0, math.max);
    final safeMaxY = maxY <= 0 ? 1.0 : maxY * 1.25;
    final total = weekPoints.fold<double>(0, (sum, p) => sum + p.value);
    final selectedIndex = weekPoints.indexWhere((p) => p.value == maxY);
    final activeIndex = selectedIndex < 0
        ? weekPoints.length - 1
        : selectedIndex;
    final activePoint = weekPoints[activeIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Expenses', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            Formatters.currency(total),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: safeMaxY,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= weekPoints.length) {
                              return const SizedBox.shrink();
                            }
                            final label = DateFormat(
                              'EEE',
                            ).format(weekPoints[idx].date);
                            final shortLabel = label.length > 3
                                ? label.substring(0, 3)
                                : label;
                            final isActive = idx == activeIndex;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: activeIndex.toDouble(),
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                          dashArray: const [4, 4],
                          strokeWidth: 1,
                        ),
                      ],
                    ),
                    lineTouchData: LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppColors.emerald,
                        barWidth: 3.2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) =>
                              spot.x.toInt() == activeIndex,
                          getDotPainter: (spot, _, __, ___) =>
                              FlDotCirclePainter(
                                radius: 6.5,
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                strokeColor: AppColors.emerald,
                                strokeWidth: 3,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.emerald.withValues(alpha: 0.26),
                              AppColors.emerald.withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                        spots: [
                          for (var i = 0; i < weekPoints.length; i++)
                            FlSpot(i.toDouble(), weekPoints[i].value),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left:
                      (activeIndex /
                          (weekPoints.length <= 1
                              ? 1
                              : weekPoints.length - 1)) *
                      (MediaQuery.of(context).size.width - 130),
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      Formatters.currency(activePoint.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
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

class _IncomeExpenseBars extends StatelessWidget {
  const _IncomeExpenseBars({
    required this.income,
    required this.expense,
    required this.isDark,
  });

  final double income;
  final double expense;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final maxY = math.max(income, expense);
    final safeMaxY = maxY <= 0 ? 1.0 : maxY * 1.25;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: BarChart(
        BarChartData(
          maxY: safeMaxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: safeMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(value == 0 ? 'Income' : 'Expense'),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipColor: (group) =>
                  isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = group.x == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n${Formatters.currency(rod.toY)}',
                  TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            _barGroup(0, income, AppColors.income),
            _barGroup(1, expense, AppColors.expense),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 34,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0.7)],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.lightSurfaceAlt,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
