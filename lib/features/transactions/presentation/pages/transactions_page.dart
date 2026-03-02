import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(monthlyTransactionsProvider);
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final month = ref.watch(selectedMonthProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final dateFrom = ref.watch(transactionDateFromFilterProvider);
    final dateTo = ref.watch(transactionDateToFilterProvider);
    final dropdownMenuColor = isDark ? const Color(0xFF16261E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Column(
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: month,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (selected != null) {
                                ref.read(selectedMonthProvider.notifier).state =
                                    DateTime(selected.year, selected.month, 1);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(DateFormat('MMM yyyy').format(month)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            isExpanded: true,
                            dropdownColor: dropdownMenuColor,
                            initialValue: ref.watch(
                              transactionTypeFilterProvider,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All')),
                              DropdownMenuItem(
                                value: 'income',
                                child: Text('Income'),
                              ),
                              DropdownMenuItem(
                                value: 'expense',
                                child: Text('Expense'),
                              ),
                            ],
                            onChanged: (value) {
                              ref
                                      .read(
                                        transactionTypeFilterProvider.notifier,
                                      )
                                      .state =
                                  value;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      dropdownColor: dropdownMenuColor,
                      initialValue: ref.watch(
                        transactionCategoryFilterProvider,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        ref
                                .read(
                                  transactionCategoryFilterProvider.notifier,
                                )
                                .state =
                            value;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dateFrom ?? month,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                final normalized = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                                ref
                                        .read(
                                          transactionDateFromFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    normalized;
                                final currentTo = ref.read(
                                  transactionDateToFilterProvider,
                                );
                                if (currentTo != null &&
                                    currentTo.isBefore(normalized)) {
                                  ref
                                          .read(
                                            transactionDateToFilterProvider
                                                .notifier,
                                          )
                                          .state =
                                      normalized;
                                }
                              }
                            },
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              dateFrom == null
                                  ? 'From'
                                  : DateFormat('dd MMM yyyy').format(dateFrom),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dateTo ?? dateFrom ?? month,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                final normalized = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                                final currentFrom = ref.read(
                                  transactionDateFromFilterProvider,
                                );
                                if (currentFrom != null &&
                                    normalized.isBefore(currentFrom)) {
                                  ref
                                          .read(
                                            transactionDateFromFilterProvider
                                                .notifier,
                                          )
                                          .state =
                                      normalized;
                                }
                                ref
                                        .read(
                                          transactionDateToFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    normalized;
                              }
                            },
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              dateTo == null
                                  ? 'To'
                                  : DateFormat('dd MMM yyyy').format(dateTo),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (dateFrom != null || dateTo != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            ref
                                    .read(
                                      transactionDateFromFilterProvider
                                          .notifier,
                                    )
                                    .state =
                                null;
                            ref
                                    .read(
                                      transactionDateToFilterProvider.notifier,
                                    )
                                    .state =
                                null;
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Clear range'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: transactions.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No transactions yet'));
                  }

                  final groups = <String, List<TransactionEntity>>{};
                  for (final item in items) {
                    final key = DateFormat('dd MMM yyyy').format(item.date);
                    groups.putIfAbsent(key, () => []).add(item);
                  }
                  final sectionKeys = groups.keys.toList(growable: false);
                  final shouldShowHint =
                      !(settings?.transactionHintsSeen ?? false);

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (shouldShowHint)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: GlassCard(
                            child: ListTile(
                              leading: const Icon(Icons.swipe_rounded),
                              title: const Text('Quick actions'),
                              subtitle: const Text(
                                'Swipe right to edit, swipe left to delete.',
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(settingsRepositoryProvider)
                                      .markTransactionHintsSeen();
                                },
                                child: const Text('Got it'),
                              ),
                            ),
                          ),
                        ),
                      for (final day in sectionKeys) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                            bottom: AppSpacing.xs,
                          ),
                          child: Text(
                            day,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        ...groups[day]!.map((item) {
                          final categoryName =
                              categories
                                  .where((c) => c.id == item.categoryId)
                                  .map((e) => e.name)
                                  .firstOrNull ??
                              item.categoryId;
                          final isIncome = item.type == TransactionType.income;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Dismissible(
                              key: ValueKey(item.id),
                              background: Container(
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  color: AppColors.expense,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddTransactionPage(existing: item),
                                    ),
                                  );
                                  return false;
                                }
                                return true;
                              },
                              onDismissed: (_) async {
                                await ref
                                    .read(transactionActionsProvider)
                                    .softDelete(item.id);
                                HapticFeedback.mediumImpact();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Transaction deleted',
                                      ),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          ref
                                              .read(transactionActionsProvider)
                                              .restore(item.id);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? const [
                                            Color(0xFF1A2E2A),
                                            Color(0xFF152722),
                                            Color(0xFF10201C),
                                          ]
                                        : const [
                                            Color(0xFFF8FCFA),
                                            Color(0xFFEEF6F1),
                                            Color(0xFFE6F0EA),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : Colors.black.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.20)
                                          : const Color(0xFFDDE9E2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      color: isIncome
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                  ),
                                  title: Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    Formatters.date(item.date),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.72)
                                          : const Color(0xFF31473D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Text(
                                    Formatters.currency(item.amount),
                                    style: TextStyle(
                                      color: isIncome
                                          ? AppColors.income
                                          : AppColors.expense,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
