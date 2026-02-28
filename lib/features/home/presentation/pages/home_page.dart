import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/home/presentation/providers/home_provider.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final recent = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          children: [
            Text('Good evening', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text('Here is your overview', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            summary.when(
              data: (data) => _HeroBalanceCard(
                balance: data.currentBalance,
                income: data.monthlyIncome,
                expense: data.monthlyExpense,
                remainingBudget: data.remainingBudget,
              ),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Failed to load: $error'))),
            ),
            const SizedBox(height: 16),
            Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            summary.when(
              data: (data) => SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatPill(
                      title: 'Budget Left',
                      value: Formatters.currency(data.remainingBudget),
                      color: data.remainingBudget >= 0 ? Colors.teal : Colors.red,
                    ),
                    _StatPill(
                      title: 'This Month Spent',
                      value: Formatters.currency(data.monthlyExpense),
                      color: Colors.red,
                    ),
                    _StatPill(
                      title: 'This Month Earned',
                      value: Formatters.currency(data.monthlyIncome),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 92),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 22),
            Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            recent.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No transactions yet. Add your first transaction.'),
                    ),
                  );
                }
                return Column(
                  children: items
                      .map(
                        (e) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: (e.type.name == 'income' ? Colors.green : Colors.red).withValues(alpha: 0.12),
                              child: Icon(
                                e.type.name == 'income' ? Icons.south_west_rounded : Icons.north_east_rounded,
                                color: e.type.name == 'income' ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(e.note?.isNotEmpty == true ? e.note! : e.categoryId),
                            subtitle: Text(Formatters.date(e.date)),
                            trailing: Text(
                              Formatters.currency(e.amount),
                              style: TextStyle(
                                color: e.type.name == 'income' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w700,
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
    final negative = remainingBudget < 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.90),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.60),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Balance', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            Formatters.currency(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _HeroMetric(label: 'Income', amount: income, color: const Color(0xFFA7F3D0))),
              Expanded(child: _HeroMetric(label: 'Expense', amount: expense, color: const Color(0xFFFECACA))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Remaining Budget: ${Formatters.currency(remainingBudget)}',
            style: TextStyle(color: negative ? const Color(0xFFFECACA) : Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.amount, required this.color});

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          Formatters.currency(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
