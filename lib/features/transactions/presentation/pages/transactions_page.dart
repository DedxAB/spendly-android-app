import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/noir_header.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionFilterProvider);
    final filterController = ref.read(transactionFilterProvider.notifier);
    final transactions = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final categoryById = {for (final c in categories) c.id: c.name};

    return Scaffold(
      appBar: NoirHeader(
        showLeading: true,
        leadingIcon: Icons.calendar_month_outlined,
        onLeadingTap: () => context.push('/calendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Text(
            'SEARCH LEDGER',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: filterController.setSearchQuery,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'MERCHANT, CATEGORY, OR AMOUNT',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 134,
              child: OutlinedButton.icon(
                onPressed: () => _openFilters(context, ref, filters),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('FILTERS'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderDark),
          transactions.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text('No transactions found'),
                );
              }
              final grouped = _groupByDate(items);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.entries
                    .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.borderDark),
                            ...entry.value.map(
                              (tx) => Dismissible(
                                key: ValueKey(tx.id),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    await showAddExpenseSheet(
                                      context,
                                      existing: tx,
                                    );
                                    return false;
                                  }
                                  return true;
                                },
                                onDismissed: (_) {
                                  ref
                                      .read(transactionActionsProvider)
                                      .softDelete(tx.id);
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  color: const Color(0xFF1A1A1A),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: const Icon(Icons.edit),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  color: const Color(0xFF1A1A1A),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: const Icon(Icons.delete),
                                ),
                                child: _HistoryRow(
                                  title:
                                      categoryById[tx.categoryId] ??
                                      tx.categoryId,
                                  subtitle: _subtitle(tx),
                                  amount: tx.amount,
                                  income: tx.type == TransactionType.income,
                                  icon: _iconFor(
                                    categoryById[tx.categoryId] ??
                                        tx.categoryId,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load: $e'),
          ),
        ],
      ),
    );
  }

  static Map<String, List<TransactionEntity>> _groupByDate(
    List<TransactionEntity> items,
  ) {
    final now = DateTime.now();
    final map = <String, List<TransactionEntity>>{};
    for (final tx in items) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final key = day == today
          ? 'Today'
          : day == yesterday
          ? 'Yesterday'
          : DateFormat('MMMM d, yyyy').format(tx.date);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  static String _subtitle(TransactionEntity tx) {
    return tx.note?.trim().isNotEmpty == true
        ? tx.note!.toUpperCase()
        : tx.paymentMode.label.toUpperCase();
  }

  static IconData _iconFor(String text) {
    final t = text.toLowerCase();
    if (t.contains('food') || t.contains('dining')) {
      return Icons.restaurant;
    }
    if (t.contains('uber') || t.contains('transport')) {
      return Icons.directions_car;
    }
    if (t.contains('shop') || t.contains('store')) {
      return Icons.shopping_bag;
    }
    if (t.contains('health') || t.contains('gym')) {
      return Icons.fitness_center;
    }
    if (t.contains('travel') || t.contains('air')) {
      return Icons.flight;
    }
    if (t.contains('transfer') || t.contains('salary')) {
      return Icons.payments;
    }
    return Icons.receipt;
  }

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    TransactionFilterState filters,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filters.type == null,
                    onSelected: (_) => ref
                        .read(transactionFilterProvider.notifier)
                        .setType(null),
                  ),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: filters.type == 'income',
                    onSelected: (_) => ref
                        .read(transactionFilterProvider.notifier)
                        .setType('income'),
                  ),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: filters.type == 'expense',
                    onSelected: (_) => ref
                        .read(transactionFilterProvider.notifier)
                        .setType('expense'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: PaymentMode.values
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m.label),
                        selected: filters.paymentMode == m,
                        onSelected: (_) => ref
                            .read(transactionFilterProvider.notifier)
                            .applyAdvanced(
                              paymentMode: filters.paymentMode == m ? null : m,
                              minAmount: filters.minAmount,
                              maxAmount: filters.maxAmount,
                              sortOption: filters.sortOption,
                              customFrom: filters.customFrom,
                              customTo: filters.customTo,
                            ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.income,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool income;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            color: const Color(0xFF1A1A1A),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: Color(0xFFC0C0C0),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${income ? '+' : '-'}${Formatters.currency(amount)}',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: income ? const Color(0xFF5DF393) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

