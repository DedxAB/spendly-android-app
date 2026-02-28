import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/investments/data/repositories/investments_repository_impl.dart';
import 'package:spendly/features/investments/domain/entities/investment_entity.dart';
import 'package:spendly/features/investments/presentation/providers/investments_provider.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:uuid/uuid.dart';

class InvestmentsPage extends ConsumerWidget {
  const InvestmentsPage({super.key});

  static const _investmentCategoryId = 'cat_investment';

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'Stock');
    final investedController = TextEditingController();
    final currentValueController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Investment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name / Symbol',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type (Stock, MF, etc.)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: investedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Invested Amount',
                      prefixText: '${AppConstants.currencySymbol} ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: currentValueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current Value (optional)',
                      prefixText: '${AppConstants.currencySymbol} ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invested Date'),
                    subtitle: Text(Formatters.date(selectedDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final type = typeController.text.trim();
                  final invested = double.tryParse(
                    investedController.text.trim(),
                  );

                  if (name.isEmpty ||
                      type.isEmpty ||
                      invested == null ||
                      invested <= 0) {
                    return;
                  }

                  final now = DateTime.now();
                  final investment = InvestmentEntity(
                    id: const Uuid().v4(),
                    name: name,
                    type: type,
                    amountInvested: invested,
                    currentValue: double.tryParse(
                      currentValueController.text.trim(),
                    ),
                    investedDate: selectedDate,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    createdAt: now,
                    updatedAt: now,
                  );

                  await ref
                      .read(investmentsRepositoryProvider)
                      .addOrUpdate(investment);
                  await _ensureInvestmentCategory(ref);
                  await ref
                      .read(transactionActionsProvider)
                      .save(
                        TransactionEntity(
                          id: const Uuid().v4(),
                          type: TransactionType.expense,
                          amount: invested,
                          categoryId: _investmentCategoryId,
                          paymentMode: PaymentMode.card,
                          note:
                              'Investment: $name${investment.note == null ? '' : ' - ${investment.note}'}',
                          date: selectedDate,
                          createdAt: now,
                          updatedAt: now,
                          isDeleted: false,
                        ),
                      );

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _ensureInvestmentCategory(WidgetRef ref) async {
    final categories = await ref
        .read(categoriesRepositoryProvider)
        .watchAll()
        .first;
    final found = categories.any(
      (c) =>
          c.id == _investmentCategoryId || c.name.toLowerCase() == 'investment',
    );
    if (found) return;

    final now = DateTime.now();
    await ref
        .read(categoriesRepositoryProvider)
        .add(
          CategoryEntity(
            id: _investmentCategoryId,
            name: 'Investment',
            icon: 'trending_up',
            color: '#6366F1',
            type: TransactionType.expense,
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(investmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: investments.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No investments added yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final current = item.currentValue;
              final pnl = current == null
                  ? null
                  : current - item.amountInvested;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GlassCard(
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${item.type} • ${Formatters.date(item.investedDate)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(item.amountInvested),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (pnl != null)
                          Text(
                            'P/L ${pnl >= 0 ? '+' : ''}${Formatters.currency(pnl)}',
                            style: TextStyle(
                              color: pnl >= 0
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                      ],
                    ),
                    onLongPress: () async {
                      await ref
                          .read(investmentsRepositoryProvider)
                          .softDelete(item.id);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}
