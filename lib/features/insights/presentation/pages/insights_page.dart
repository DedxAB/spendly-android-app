import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/insights/presentation/providers/insights_provider.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distribution = ref.watch(expenseDistributionProvider);
    final trend = ref.watch(dailyTrendProvider);
    final compare = ref.watch(incomeVsExpenseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Expense Distribution', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 220,
              child: distribution.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('No expense data'));
                  return PieChart(PieChartData(sections: [
                    for (final slice in items)
                      PieChartSectionData(value: slice.total, title: slice.category, color: Formatters.parseHexColor(slice.color), radius: 80),
                  ]));
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Daily Spending Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 220,
              child: trend.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('No trend data'));
                  return LineChart(LineChartData(lineBarsData: [
                    LineChartBarData(isCurved: true, spots: [for (var i = 0; i < items.length; i++) FlSpot(i.toDouble(), items[i].value)]),
                  ]));
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Income vs Expense', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 220,
              child: compare.when(
                data: (map) {
                  final income = map['income'] ?? 0;
                  final expense = map['expense'] ?? 0;
                  return BarChart(BarChartData(
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: Colors.green)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, color: Colors.red)]),
                    ],
                    titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) => Text(value == 0 ? 'Income' : 'Expense')))),
                  ));
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

