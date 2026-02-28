import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: month,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selected != null) {
                          ref.read(selectedMonthProvider.notifier).state = DateTime(selected.year, selected.month, 1);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM yyyy').format(month)),
                    ),
                    const Spacer(),
                    DropdownButton<String?>(
                      value: ref.watch(transactionTypeFilterProvider),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      ],
                      onChanged: (value) => ref.read(transactionTypeFilterProvider.notifier).state = value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactions.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('No transactions yet'));
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final categoryName = categories.where((c) => c.id == item.categoryId).map((e) => e.name).firstOrNull ?? item.categoryId;
                      final isIncome = item.type.name == 'income';
                      return Dismissible(
                        key: ValueKey(item.id),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTransactionPage(existing: item)));
                            return false;
                          }
                          return true;
                        },
                        onDismissed: (_) async {
                          await ref.read(transactionActionsProvider).softDelete(item.id);
                          HapticFeedback.mediumImpact();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Transaction deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () => ref.read(transactionActionsProvider).restore(item.id),
                                ),
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.12),
                              child: Icon(
                                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.note ?? ''} • ${Formatters.date(item.date)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              Formatters.currency(item.amount),
                              style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Failed to load: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
