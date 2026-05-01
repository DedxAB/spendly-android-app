import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/noir_header.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final budget = settings?.monthlyBudget ?? 0;
    final transactions =
        ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];

    final now = DateTime.now();
    final monthlyItems = transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .toList(growable: false);

    final monthlySpend = monthlyItems.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final remaining = budget - monthlySpend;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leftDays = (daysInMonth - now.day + 1).clamp(1, 31);
    final safePerDay = remaining / leftDays;

    final byCategory = <String, double>{};
    for (final tx in monthlyItems) {
      byCategory[tx.categoryId] = (byCategory[tx.categoryId] ?? 0) + tx.amount;
    }

    final categoryCards = byCategory.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: NoirHeader(
        showLeading: true,
        leadingIcon: Icons.notifications_none_rounded,
        onLeadingTap: () => context.push('/notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Budget',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('MMMM').format(now)} Overview',
            style: const TextStyle(color: Color(0xFFC5C5C5)),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderDark),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderDark),
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Health',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'TOTAL AVAILABLE VS USED',
                  style: TextStyle(
                    letterSpacing: 1.8,
                    fontSize: 11,
                    color: Color(0xFFAFAFAF),
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white),
                    children: [
                      TextSpan(
                        text: Formatters.currency(monthlySpend),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${Formatters.currency(budget)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFC8C8C8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: budget <= 0 ? 0 : (monthlySpend / budget).clamp(0, 1),
                  minHeight: 8,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF2F2F2F),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${(budget <= 0 ? 0 : ((monthlySpend / budget) * 100)).toStringAsFixed(0)}% Used',
                    ),
                    const Spacer(),
                    Text(
                      '${Formatters.currency(remaining.abs())} ${remaining >= 0 ? 'Remaining' : 'Over'}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.borderDark),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Safe to Spend',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB8B8B8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${safePerDay >= 0 ? Formatters.currency(safePerDay) : '-${Formatters.currency(safePerDay.abs())}'} / day',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: safePerDay >= 0
                                  ? const Color(0xFF59F28F)
                                  : const Color(0xFFFFB3A8),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF797979)),
                      ),
                      child: Text(
                        remaining >= 0 ? 'ON TRACK' : 'OVER BUDGET',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _openBudgetEditor(context, ref, budget),
                child: const Text('EDIT BUDGETS'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...categoryCards.map((entry) {
            final category = categories
                .where((c) => c.id == entry.key)
                .firstOrNull;
            final spend = entry.value;
            final allocated = _allocatedForCategory(
              budget,
              categoryCards.length,
              entry.key.hashCode,
            );
            final ratio = allocated <= 0 ? 0.0 : spend / allocated;
            final over = ratio > 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BudgetCategoryCard(
                name: category?.name ?? entry.key,
                icon: _iconFor(category?.name ?? entry.key),
                spend: spend,
                allocated: allocated,
                ratio: ratio,
                overBudget: over,
              ),
            );
          }),
        ],
      ),
    );
  }

  static double _allocatedForCategory(double totalBudget, int count, int seed) {
    if (count <= 0 || totalBudget <= 0) return 0;
    final base = totalBudget / count;
    final offset = ((seed.abs() % 21) - 10) / 100;
    return (base * (1 + offset)).clamp(base * 0.6, base * 1.4);
  }

  static IconData _iconFor(String text) {
    final t = text.toLowerCase();
    if (t.contains('house') || t.contains('rent') || t.contains('home')) {
      return Icons.home;
    }
    if (t.contains('food') || t.contains('dining')) {
      return Icons.restaurant;
    }
    if (t.contains('transport') || t.contains('uber')) {
      return Icons.directions_car;
    }
    if (t.contains('util')) {
      return Icons.flash_on;
    }
    if (t.contains('shop')) {
      return Icons.shopping_bag;
    }
    if (t.contains('entertain')) {
      return Icons.local_activity;
    }
    return Icons.category;
  }

  Future<void> _openBudgetEditor(
    BuildContext context,
    WidgetRef ref,
    double currentBudget,
  ) async {
    final budgetController = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Budget',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly Budget',
                hintText: 'e.g. 25000',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final next = double.tryParse(budgetController.text.trim());
                  if (next == null || next < 0) return;
                  await ref.read(settingsRepositoryProvider).setBudget(next);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('Save Monthly Budget'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/categories');
                },
                child: const Text('Add / Manage Categories'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.name,
    required this.icon,
    required this.spend,
    required this.allocated,
    required this.ratio,
    required this.overBudget,
  });

  final String name;
  final IconData icon;
  final double spend;
  final double allocated;
  final double ratio;
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    final remaining = allocated - spend;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: overBudget ? const Color(0xFFFFB3A8) : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: overBudget ? const Color(0xFFFFB3A8) : Colors.white,
                  ),
                ),
              ),
              if (overBudget)
                const Text(
                  'OVER BUDGET',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: Color(0xFFFFB3A8),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 17,
                color: overBudget ? const Color(0xFFFFB3A8) : Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${Formatters.currency(spend)} / ${Formatters.currency(allocated)}',
            style: TextStyle(
              color: overBudget
                  ? const Color(0xFFFFB3A8)
                  : const Color(0xFFE1E1E1),
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: ratio.clamp(0, 1.6),
            minHeight: 4,
            color: overBudget ? const Color(0xFFFFB3A8) : Colors.white,
            backgroundColor: const Color(0xFF2F2F2F),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${(ratio * 100).toStringAsFixed(0)}%'),
              const Spacer(),
              Text(
                '${remaining >= 0 ? Formatters.currency(remaining) : '-${Formatters.currency(remaining.abs())}'} ${remaining >= 0 ? 'Left' : 'Over'}',
                style: TextStyle(
                  color: overBudget
                      ? const Color(0xFFFFB3A8)
                      : const Color(0xFFD0D0D0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

