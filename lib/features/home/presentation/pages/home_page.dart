import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/home/presentation/providers/home_provider.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final todaySpent = ref.watch(todaySpentProvider).valueOrNull ?? 0;
    final recent = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Good Evening, Arnab',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your financial overview',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          summary.when(
            data: (data) => _HeroBalanceCard(
              balance: data.currentBalance,
              income: data.monthlyIncome,
              expense: data.monthlyExpense,
              remainingBudget: data.remainingBudget,
            ),
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) =>
                GlassCard(child: Text('Failed to load: $error')),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          summary.when(
            data: (data) {
              final savingsPct = data.monthlyIncome <= 0
                  ? 0.0
                  : ((data.monthlyIncome - data.monthlyExpense) /
                            data.monthlyIncome) *
                        100;
              return SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatPill(
                      title: 'Today Spent',
                      value: Formatters.currency(todaySpent),
                      color: AppColors.expense,
                    ),
                    _StatPill(
                      title: 'Remaining Budget',
                      value: Formatters.currency(data.remainingBudget),
                      color: data.remainingBudget < 0
                          ? AppColors.expense
                          : AppColors.emerald,
                    ),
                    _StatPill(
                      title: 'Savings %',
                      value: '${savingsPct.toStringAsFixed(1)}%',
                      color: savingsPct < 0
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 96),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          recent.when(
            data: (items) {
              if (items.isEmpty) {
                return const GlassCard(
                  child: Text(
                    'No transactions yet. Add your first transaction.',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  (e.type == TransactionType.income
                                          ? AppColors.income
                                          : AppColors.expense)
                                      .withValues(alpha: 0.15),
                              child: Icon(
                                e.type == TransactionType.income
                                    ? Icons.south_west_rounded
                                    : Icons.north_east_rounded,
                                color: e.type == TransactionType.income
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                            title: Text(
                              e.note?.isNotEmpty == true
                                  ? e.note!
                                  : e.categoryId,
                            ),
                            subtitle: Text(Formatters.date(e.date)),
                            trailing: Text(
                              Formatters.currency(e.amount),
                              style: TextStyle(
                                color: e.type == TransactionType.income
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load: $error'),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.remainingBudget,
  });

  final double balance;
  final double income;
  final double expense;
  final double remainingBudget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        color: scheme.primary.withValues(alpha: 0.10),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.currency(balance),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Monthly Income',
                  value: income,
                  color: AppColors.income,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Monthly Expense',
                  value: expense,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Remaining Budget: ${Formatters.currency(remainingBudget)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: remainingBudget < 0 ? AppColors.expense : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          Formatters.currency(value),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
