import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/insights/domain/entities/insight_point.dart';
import 'package:spendly/features/insights/presentation/providers/insights_provider.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  int _selectedRange = 1; // 0 week, 1 month, 2 year
  int _selectedSpotIndex = 0;

  @override
  Widget build(BuildContext context) {
    final distribution = ref.watch(expenseDistributionProvider);
    final trend = ref.watch(dailyTrendProvider);
    final compare = ref.watch(incomeVsExpenseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionTitle('Expense Distribution'),
          Card(
            child: SizedBox(
              height: 260,
              child: distribution.when(
                data: (items) {
                  if (items.isEmpty)
                    return const Center(child: Text('No expense data'));
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 38,
                              sections: [
                                for (final slice in items)
                                  PieChartSectionData(
                                    value: slice.total,
                                    color: Formatters.parseHexColor(
                                      slice.color,
                                    ),
                                    radius: 56,
                                    title: '',
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final slice in items.take(4))
                              _LegendChip(
                                color: Formatters.parseHexColor(slice.color),
                                label: slice.category,
                              ),
                          ],
                        ),
                      ],
                    ),
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
                  if (items.isEmpty)
                    return const Center(child: Text('No trend data'));
                  if (_selectedSpotIndex >= items.length)
                    _selectedSpotIndex = items.length - 1;
                  return _ReferenceStyleTrendCard(
                    points: items,
                    selectedRange: _selectedRange,
                    selectedSpotIndex: _selectedSpotIndex,
                    onRangeChanged: (value) =>
                        setState(() => _selectedRange = value),
                    onSpotChanged: (value) =>
                        setState(() => _selectedSpotIndex = value),
                  );
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
              height: 240,
              child: compare.when(
                data: (map) {
                  final income = map['income'] ?? 0;
                  final expense = map['expense'] ?? 0;
                  final maxY = (income > expense ? income : expense) * 1.3;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    child: BarChart(
                      BarChartData(
                        maxY: maxY == 0 ? 1 : maxY,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) =>
                                  Text(value == 0 ? 'Income' : 'Expense'),
                            ),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: income,
                                color: AppColors.income,
                                width: 24,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: expense,
                                color: AppColors.expense,
                                width: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _ReferenceStyleTrendCard extends StatelessWidget {
  const _ReferenceStyleTrendCard({
    required this.points,
    required this.selectedRange,
    required this.selectedSpotIndex,
    required this.onRangeChanged,
    required this.onSpotChanged,
  });

  final List<InsightPoint> points;
  final int selectedRange;
  final int selectedSpotIndex;
  final ValueChanged<int> onRangeChanged;
  final ValueChanged<int> onSpotChanged;

  @override
  Widget build(BuildContext context) {
    final selectedPoint = points[selectedSpotIndex];
    final monthLabels = points
        .map((e) => DateFormat('MMM').format(e.date))
        .toList(growable: false);
    final maxY = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chartColor = dark ? Colors.white : const Color(0xFF171A1D);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          Text(
            Formatters.currency(selectedPoint.value),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd MMM, yyyy').format(selectedPoint.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            segments: const [
              ButtonSegment(value: 0, label: Text('Week')),
              ButtonSegment(value: 1, label: Text('Month')),
              ButtonSegment(value: 2, label: Text('Year')),
            ],
            selected: {selectedRange},
            onSelectionChanged: (set) => onRangeChanged(set.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY == 0 ? 1 : maxY * 1.25,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
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
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= monthLabels.length)
                              return const SizedBox.shrink();
                            final selected = idx == selectedSpotIndex;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                monthLabels[idx],
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
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
                          x: selectedSpotIndex.toDouble(),
                          color: Theme.of(context).dividerColor,
                          dashArray: const [4, 4],
                          strokeWidth: 1,
                        ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 0,
                        getTooltipItems: (_) => [],
                      ),
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((_) {
                          return TouchedSpotIndicatorData(
                            FlLine(color: Colors.transparent),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) =>
                                  FlDotCirclePainter(
                                    radius: 8,
                                    color: Colors.white,
                                    strokeColor: chartColor,
                                    strokeWidth: 3,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                      touchCallback: (event, response) {
                        if (response?.lineBarSpots?.isNotEmpty == true) {
                          onSpotChanged(
                            response!.lineBarSpots!.first.spotIndex,
                          );
                        }
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: chartColor,
                        barWidth: 3.2,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) =>
                              spot.x.toInt() == selectedSpotIndex,
                          getDotPainter: (spot, _, __, ___) =>
                              FlDotCirclePainter(
                                radius: 8,
                                color: Colors.white,
                                strokeColor: chartColor,
                                strokeWidth: 3,
                              ),
                        ),
                        belowBarData: BarAreaData(show: false),
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].value),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left:
                      (selectedSpotIndex /
                          (points.length <= 1 ? 1 : points.length - 1)) *
                      (MediaQuery.of(context).size.width - 120),
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      Formatters.currency(selectedPoint.value),
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
