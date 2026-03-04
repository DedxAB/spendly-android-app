import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/insights/domain/entities/expense_slice.dart';
import 'package:spendly/features/insights/domain/entities/income_expense_bar.dart';
import 'package:spendly/features/insights/domain/entities/insight_point.dart';
import 'package:spendly/features/insights/domain/entities/monthly_reflection_entity.dart';
import 'package:spendly/features/insights/presentation/providers/insights_provider.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  final TextEditingController _reflectionController = TextEditingController();
  bool _isSavingReflection = false;
  int _touchedPieIndex = -1;

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(insightsSelectedMonthProvider);
    final viewMode = ref.watch(insightsViewModeProvider);
    final isYearly = viewMode == InsightsViewMode.yearly;

    final incomeExpense = ref.watch(incomeVsExpenseProvider);
    final distribution = ref.watch(expenseDistributionProvider);
    final trend = ref.watch(dailyTrendProvider);
    final yearlyBars = ref.watch(yearlyIncomeVsExpenseProvider);
    final paymentModes = ref.watch(paymentModeBreakdownProvider);
    final projection = ref.watch(projectedExpenseProvider);
    final changePercent = ref.watch(expenseChangePercentProvider);
    final reflection = ref.watch(monthlyReflectionProvider);
    final monthlyBudget = ref.watch(monthlyBudgetProvider);

    reflection.whenData((value) {
      final saved = value?.note ?? '';
      if (_reflectionController.text != saved) {
        _reflectionController.text = saved;
      }
    });

    final summary =
        incomeExpense.valueOrNull ?? {'income': 0.0, 'expense': 0.0};
    final income = (summary['income'] ?? 0).toDouble();
    final expense = (summary['expense'] ?? 0).toDouble();
    final net = income - expense;
    final budgetTarget = isYearly ? monthlyBudget * 12 : monthlyBudget;
    final budgetUsedPercent = budgetTarget <= 0
        ? 0.0
        : (expense / budgetTarget) * 100;
    final remainingBudget = budgetTarget - expense;

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _TimeFilterSection(
            month: selectedMonth,
            viewMode: viewMode,
            onPrevious: () {
              ref.read(insightsSelectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
                1,
              );
            },
            onNext: () {
              ref.read(insightsSelectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
                1,
              );
            },
            onModeChanged: (mode) {
              ref.read(insightsViewModeProvider.notifier).state = mode;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _FinancialSummaryCard(
            income: income,
            expense: expense,
            net: net,
            budgetUsedPercent: budgetUsedPercent,
            remainingBudget: remainingBudget,
            hasBudget: budgetTarget > 0,
            isYearly: isYearly,
          ),
          if (!isYearly) ...[
            const SizedBox(height: AppSpacing.md),
            _BudgetProjectionCard(
              projectedExpense: projection.valueOrNull ?? 0,
              budget: monthlyBudget,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          distribution.when(
            data: (slices) => _ExpenseDistributionSection(
              slices: _topFiveWithOthers(slices),
              touchedIndex: _touchedPieIndex,
              onTouchChanged: (index) =>
                  setState(() => _touchedPieIndex = index),
            ),
            loading: () => const _LoadingCard(height: 300),
            error: (_, __) =>
                const _ErrorCard(message: 'Could not load expense split'),
          ),
          const SizedBox(height: AppSpacing.md),
          trend.when(
            data: (points) => _TrendSection(
              points: points,
              changePercent: changePercent.valueOrNull,
              isYearly: isYearly,
            ),
            loading: () => const _LoadingCard(height: 280),
            error: (_, __) => const _ErrorCard(message: 'Could not load trend'),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isYearly
                  ? yearlyBars.when(
                      data: (bars) => _IncomeExpenseYearlyBars(bars: bars),
                      loading: () => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) =>
                          const Text('Could not load yearly comparison'),
                    )
                  : _IncomeExpenseMonthlyBars(income: income, expense: expense),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          paymentModes.when(
            data: (breakdown) => _PaymentModeSection(breakdown: breakdown),
            loading: () => const _LoadingCard(height: 160),
            error: (_, __) =>
                const _ErrorCard(message: 'Could not load payment split'),
          ),
          const SizedBox(height: AppSpacing.md),
          _MonthlyReflectionSection(
            month: selectedMonth,
            reflection: reflection.valueOrNull,
            controller: _reflectionController,
            isSaving: _isSavingReflection,
            onSave: _saveReflection,
          ),
        ],
      ),
    );
  }

  List<ExpenseSlice> _topFiveWithOthers(List<ExpenseSlice> source) {
    if (source.length <= 5) return source;
    final sorted = [...source]..sort((a, b) => b.total.compareTo(a.total));
    final topFive = sorted.take(5).toList(growable: true);
    final othersTotal = sorted
        .skip(5)
        .fold<double>(0, (sum, item) => sum + item.total);
    if (othersTotal > 0) {
      topFive.add(
        ExpenseSlice(category: 'Others', color: '#6B7280', total: othersTotal),
      );
    }
    return topFive;
  }

  Future<void> _saveReflection() async {
    final note = _reflectionController.text.trim();
    if (note.isEmpty || _isSavingReflection) return;
    setState(() => _isSavingReflection = true);
    try {
      await ref.read(saveMonthlyReflectionProvider)(note);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reflection saved')));
    } finally {
      if (mounted) setState(() => _isSavingReflection = false);
    }
  }
}

class _TimeFilterSection extends StatelessWidget {
  const _TimeFilterSection({
    required this.month,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onModeChanged,
  });

  final DateTime month;
  final InsightsViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<InsightsViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              viewMode == InsightsViewMode.monthly
                  ? 'Month-to-date'
                  : 'Year view',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _modeToggle(
                    context: context,
                    label: 'Monthly',
                    selected: viewMode == InsightsViewMode.monthly,
                    onTap: () => onModeChanged(InsightsViewMode.monthly),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _modeToggle(
                    context: context,
                    label: 'Yearly',
                    selected: viewMode == InsightsViewMode.yearly,
                    onTap: () => onModeChanged(InsightsViewMode.yearly),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeToggle({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = AppColors.emerald.withValues(alpha: 0.24);
    final unselectedBg = isDark
        ? AppColors.darkSurfaceAlt.withValues(alpha: 0.92)
        : AppColors.lightSurfaceAlt.withValues(alpha: 0.95);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? selectedBg : unselectedBg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: selected
              ? AppColors.emerald.withValues(alpha: 0.76)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08)),
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? (isDark
                            ? const Color(0xFFE9F9EC)
                            : const Color(0xFF123122))
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.86),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.income,
    required this.expense,
    required this.net,
    required this.budgetUsedPercent,
    required this.remainingBudget,
    required this.hasBudget,
    required this.isYearly,
  });

  final double income;
  final double expense;
  final double net;
  final double budgetUsedPercent;
  final double remainingBudget;
  final bool hasBudget;
  final bool isYearly;

  @override
  Widget build(BuildContext context) {
    final percentLabel = hasBudget
        ? '${budgetUsedPercent.clamp(0, 999).toStringAsFixed(0)}%'
        : '--';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isYearly ? 'Yearly Summary' : 'Financial Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Total Income',
              value: Formatters.currency(income),
              color: AppColors.income,
            ),
            _SummaryRow(
              label: 'Total Expense',
              value: Formatters.currency(expense),
              color: AppColors.expense,
            ),
            _SummaryRow(
              label: 'Net Balance',
              value: Formatters.currency(net),
              color: net >= 0 ? AppColors.income : AppColors.expense,
            ),
            const Divider(height: AppSpacing.lg),
            _SummaryRow(label: 'Budget Used', value: percentLabel),
            _SummaryRow(
              label: 'Remaining Budget',
              value: hasBudget
                  ? Formatters.currency(remainingBudget)
                  : 'No budget set',
              color: remainingBudget >= 0
                  ? AppColors.income
                  : AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProjectionCard extends StatelessWidget {
  const _BudgetProjectionCard({
    required this.projectedExpense,
    required this.budget,
  });

  final double projectedExpense;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final exceeds = budget > 0 && projectedExpense > budget;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Projection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'If current spending continues, you will spend ${Formatters.currency(projectedExpense)} this month.',
            ),
            if (exceeds) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Projected spend is above budget.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseDistributionSection extends StatelessWidget {
  const _ExpenseDistributionSection({
    required this.slices,
    required this.touchedIndex,
    required this.onTouchChanged,
  });

  final List<ExpenseSlice> slices;
  final int touchedIndex;
  final ValueChanged<int> onTouchChanged;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const _ErrorCard(message: 'No expense data for this period');
    }

    final total = slices.fold<double>(0, (sum, item) => sum + item.total);
    final topThree = [...slices]..sort((a, b) => b.total.compareTo(a.total));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 210,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 46,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        onTouchChanged(-1);
                        return;
                      }
                      onTouchChanged(
                        response!.touchedSection!.touchedSectionIndex,
                      );
                    },
                  ),
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        value: slices[i].total,
                        title: '',
                        color: Formatters.parseHexColor(slices[i].color),
                        radius: i == touchedIndex ? 72 : 64,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Total ${Formatters.currency(total)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < math.min(3, topThree.length); i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text('${i + 1}. ${topThree[i].category}')),
                    Text(
                      Formatters.currency(topThree[i].total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({
    required this.points,
    required this.changePercent,
    required this.isYearly,
  });

  final List<InsightPoint> points;
  final double? changePercent;
  final bool isYearly;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _ErrorCard(message: 'No trend data for this period');
    }

    final maxY = points.map((e) => e.value).fold<double>(0, math.max);
    final safeMaxY = (maxY <= 0 ? 1 : maxY * 1.2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isYearly ? 'Monthly Spending Trend' : 'Daily Spending Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: safeMaxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length)
                            return const SizedBox.shrink();
                          final label = isYearly
                              ? DateFormat('MMM').format(points[index].date)
                              : DateFormat('d').format(points[index].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].value),
                      ],
                      isCurved: true,
                      color: AppColors.emerald,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.emerald.withValues(alpha: 0.28),
                            AppColors.emerald.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _changeLabel(changePercent, isYearly),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _changeLabel(double? percent, bool isYearly) {
    if (percent == null) return 'Not enough previous data for comparison.';
    final abs = percent.abs().toStringAsFixed(1);
    final direction = percent >= 0 ? 'increased' : 'decreased';
    final suffix = isYearly
        ? 'compared to last year'
        : 'compared to last month';
    return 'Spending $direction by $abs% $suffix.';
  }
}

class _IncomeExpenseMonthlyBars extends StatelessWidget {
  const _IncomeExpenseMonthlyBars({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income vs Expense',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SimpleBar(
          label: 'Income',
          amount: income,
          color: AppColors.income,
          max: math.max(income, expense),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SimpleBar(
          label: 'Expense',
          amount: expense,
          color: AppColors.expense,
          max: math.max(income, expense),
        ),
      ],
    );
  }
}

class _SimpleBar extends StatelessWidget {
  const _SimpleBar({
    required this.label,
    required this.amount,
    required this.color,
    required this.max,
  });

  final String label;
  final double amount;
  final Color color;
  final double max;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (amount / max).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(
              Formatters.currency(amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 12,
            color: color,
            backgroundColor: color.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _IncomeExpenseYearlyBars extends StatelessWidget {
  const _IncomeExpenseYearlyBars({required this.bars});

  final List<IncomeExpenseBar> bars;

  @override
  Widget build(BuildContext context) {
    final maxY = bars.fold<double>(
      0,
      (max, item) => math.max(max, math.max(item.income, item.expense)),
    );
    final safeMaxY = (maxY <= 0 ? 1 : maxY * 1.25).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income vs Expense (Jan-Dec)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: safeMaxY,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= bars.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bars[index].label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].income,
                        width: 6,
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.income,
                      ),
                      BarChartRodData(
                        toY: bars[i].expense,
                        width: 6,
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.expense,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentModeSection extends StatelessWidget {
  const _PaymentModeSection({required this.breakdown});

  final Map<String, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('UPI', breakdown['upi'] ?? 0),
      ('Cash', breakdown['cash'] ?? 0),
      ('Card', breakdown['card'] ?? 0),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Mode Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(row.$1),
                        const Spacer(),
                        Text('${row.$2.toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (row.$2 / 100).clamp(0, 1).toDouble(),
                        minHeight: 10,
                        color: AppColors.emerald,
                        backgroundColor: AppColors.emerald.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyReflectionSection extends StatelessWidget {
  const _MonthlyReflectionSection({
    required this.month,
    required this.reflection,
    required this.controller,
    required this.isSaving,
    required this.onSave,
  });

  final DateTime month;
  final MonthlyReflectionEntity? reflection;
  final TextEditingController controller;
  final bool isSaving;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final isCompletedMonth = _isCompleted(month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Reflection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!isCompletedMonth)
              Text(
                'Reflection becomes available after month completion.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              Text(
                'How was your financial discipline this month?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write a short reflection',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: isSaving ? null : onSave,
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ),
              if (reflection != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Last updated: ${Formatters.date(reflection!.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  bool _isCompleted(DateTime month) {
    final now = DateTime.now();
    final nextMonthStart = DateTime(month.year, month.month + 1, 1);
    final currentMonthStart = DateTime(now.year, now.month, 1);
    return nextMonthStart.isBefore(currentMonthStart) ||
        nextMonthStart.isAtSameMomentAs(currentMonthStart);
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message),
      ),
    );
  }
}
