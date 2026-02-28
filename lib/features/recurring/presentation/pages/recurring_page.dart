import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
import 'package:spendly/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:uuid/uuid.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final categories = await ref
        .read(categoriesRepositoryProvider)
        .watchByType(TransactionType.expense.value)
        .first;
    if (!context.mounted) return;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an expense category first.'),
        ),
      );
      return;
    }

    CategoryEntity selectedCategory = categories.first;
    PaymentMode selectedPaymentMode = PaymentMode.upi;
    RecurringFrequency selectedFrequency = RecurringFrequency.monthly;
    DateTime selectedStartDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Recurring Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${AppConstants.currencySymbol} ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CategoryEntity>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RecurringFrequency>(
                    initialValue: selectedFrequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(
                        value: RecurringFrequency.weekly,
                        child: Text('Weekly'),
                      ),
                      DropdownMenuItem(
                        value: RecurringFrequency.monthly,
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(
                        value: RecurringFrequency.yearly,
                        child: Text('Yearly'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedFrequency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<PaymentMode>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentMode.cash,
                        label: Text('Cash'),
                      ),
                      ButtonSegment(value: PaymentMode.upi, label: Text('UPI')),
                      ButtonSegment(
                        value: PaymentMode.card,
                        label: Text('Card'),
                      ),
                    ],
                    selected: {selectedPaymentMode},
                    onSelectionChanged: (value) {
                      setState(() => selectedPaymentMode = value.first);
                    },
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
                    title: const Text('Start Date'),
                    subtitle: Text(Formatters.date(selectedStartDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setState(() => selectedStartDate = picked);
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
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0) return;

                  final now = DateTime.now();
                  final rule = RecurringRuleEntity(
                    id: const Uuid().v4(),
                    title: title,
                    amount: amount,
                    categoryId: selectedCategory.id,
                    paymentMode: selectedPaymentMode,
                    frequency: selectedFrequency,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    startDate: selectedStartDate,
                    nextDueDate: selectedStartDate,
                    createdAt: now,
                    updatedAt: now,
                    isActive: true,
                    isDeleted: false,
                  );

                  await ref.read(recurringRepositoryProvider).addOrUpdate(rule);
                  await ref.read(recurringRepositoryProvider).processDueRules();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
      body: rules.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No recurring expenses yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GlassCard(
                  child: ListTile(
                    leading: Icon(
                      item.isActive ? Icons.repeat : Icons.pause_circle_outline,
                      color: item.isActive
                          ? AppColors.emerald
                          : Theme.of(context).colorScheme.outline,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${item.frequency.value.toUpperCase()} | Next: ${Formatters.date(item.nextDueDate)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Switch(
                          value: item.isActive,
                          onChanged: (value) async {
                            await ref
                                .read(recurringRepositoryProvider)
                                .setActive(item.id, value);
                          },
                        ),
                      ],
                    ),
                    onLongPress: () async {
                      await ref
                          .read(recurringRepositoryProvider)
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
