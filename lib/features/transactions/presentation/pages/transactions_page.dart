import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  Future<void> _openTransactionDetail(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity transaction,
    String categoryName,
  ) async {
    RecurringRuleEntity? recurringRule;
    if (transaction.recurringRuleId != null) {
      recurringRule = await ref
          .read(recurringRepositoryProvider)
          .getById(transaction.recurringRuleId!);
    }
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formatters.currency(transaction.amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: transaction.type == TransactionType.income
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Date: ${Formatters.date(transaction.date)}'),
                if (transaction.note?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('Note: ${transaction.note}'),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (recurringRule != null) ...[
                  Text(
                    'Recurring: Repeats ${_frequencyLabel(recurringRule.frequency)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _editRecurring(context, ref, recurringRule!);
                        },
                        child: const Text('Edit repeat'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(recurringRepositoryProvider)
                              .setActive(recurringRule!.id, false);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Stop recurring'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editRecurring(
    BuildContext context,
    WidgetRef ref,
    RecurringRuleEntity rule,
  ) async {
    final choice = await showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Does not repeat'),
                onTap: () =>
                    Navigator.of(context).pop(_RecurringEditAction.stop),
              ),
              ListTile(
                title: const Text('Daily'),
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.daily),
              ),
              ListTile(
                title: const Text('Weekly'),
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.weekly),
              ),
              ListTile(
                title: const Text('Monthly'),
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.monthly),
              ),
              ListTile(
                title: const Text('Yearly'),
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.yearly),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null) return;
    if (choice == _RecurringEditAction.stop) {
      await ref.read(recurringRepositoryProvider).setActive(rule.id, false);
      return;
    }
    await ref
        .read(recurringRepositoryProvider)
        .updateFrequency(rule.id, choice as RecurringFrequency);
  }

  Future<_RecurringDeleteAction?> _pickRecurringDeleteAction(
    BuildContext context,
  ) {
    return showModalBottomSheet<_RecurringDeleteAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Delete this occurrence only'),
                onTap: () =>
                    Navigator.of(context).pop(_RecurringDeleteAction.onlyThis),
              ),
              ListTile(
                title: const Text('Delete this and future occurrences'),
                onTap: () => Navigator.of(
                  context,
                ).pop(_RecurringDeleteAction.thisAndFuture),
              ),
            ],
          ),
        );
      },
    );
  }

  String _frequencyLabel(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  String _datePresetLabel(TransactionDatePreset preset) {
    switch (preset) {
      case TransactionDatePreset.thisMonth:
        return 'This Month';
      case TransactionDatePreset.lastMonth:
        return 'Last Month';
      case TransactionDatePreset.thisYear:
        return 'This Year';
      case TransactionDatePreset.custom:
        return 'Custom Range';
    }
  }

  String _sortLabel(TransactionSortOption sort) {
    switch (sort) {
      case TransactionSortOption.newestFirst:
        return 'Newest first';
      case TransactionSortOption.oldestFirst:
        return 'Oldest first';
      case TransactionSortOption.highestAmount:
        return 'Highest amount';
      case TransactionSortOption.lowestAmount:
        return 'Lowest amount';
    }
  }

  String _typeLabel(String type) {
    if (type == 'income') return 'Income';
    if (type == 'expense') return 'Expense';
    return type;
  }

  Future<void> _pickCustomDateRange(
    BuildContext context,
    WidgetRef ref,
    TransactionFilterState filters,
  ) async {
    final range = filters.effectiveRange(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );
    if (picked == null) {
      return;
    }
    ref
        .read(transactionFilterProvider.notifier)
        .setCustomRange(picked.start, picked.end);
  }

  Future<void> _openAdvancedFilters(
    BuildContext context,
    WidgetRef ref,
    TransactionFilterState filters,
  ) async {
    final minController = TextEditingController(
      text: filters.minAmount?.toStringAsFixed(0) ?? '',
    );
    final maxController = TextEditingController(
      text: filters.maxAmount?.toStringAsFixed(0) ?? '',
    );
    var draftPayment = filters.paymentMode;
    var draftSort = filters.sortOption;
    DateTime? draftFrom = filters.customFrom;
    DateTime? draftTo = filters.customTo;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Advanced Filters'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(dialogContext).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _styledFilterChip(
                            dialogContext,
                            label: 'All Accounts',
                            selected: draftPayment == null,
                            onSelected: () =>
                                setState(() => draftPayment = null),
                          ),
                          for (final mode in PaymentMode.values)
                            _styledFilterChip(
                              dialogContext,
                              label: mode.value.toUpperCase(),
                              selected: draftPayment == mode,
                              onSelected: () =>
                                  setState(() => draftPayment = mode),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Amount Range',
                        style: Theme.of(dialogContext).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Min',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Max',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Sort',
                        style: Theme.of(dialogContext).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final sort in TransactionSortOption.values)
                            _styledFilterChip(
                              dialogContext,
                              label: _sortLabel(sort),
                              selected: draftSort == sort,
                              onSelected: () =>
                                  setState(() => draftSort = sort),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: dialogContext,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDateRange:
                                (draftFrom != null && draftTo != null)
                                ? DateTimeRange(
                                    start: draftFrom!,
                                    end: draftTo!,
                                  )
                                : null,
                          );
                          if (picked == null) return;
                          setState(() {
                            draftFrom = DateTime(
                              picked.start.year,
                              picked.start.month,
                              picked.start.day,
                            );
                            draftTo = DateTime(
                              picked.end.year,
                              picked.end.month,
                              picked.end.day,
                              23,
                              59,
                              59,
                            );
                          });
                        },
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          (draftFrom != null && draftTo != null)
                              ? 'Custom: ${DateFormat('dd MMM').format(draftFrom!)} - ${DateFormat('dd MMM').format(draftTo!)}'
                              : 'Set custom date range',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      draftFrom = null;
                      draftTo = null;
                      minController.clear();
                      maxController.clear();
                      draftPayment = null;
                      draftSort = TransactionSortOption.newestFirst;
                    });
                  },
                  child: const Text('Clear advanced'),
                ),
                FilledButton(
                  onPressed: () {
                    final min = double.tryParse(minController.text.trim());
                    final max = double.tryParse(maxController.text.trim());
                    ref
                        .read(transactionFilterProvider.notifier)
                        .applyAdvanced(
                          paymentMode: draftPayment,
                          minAmount: min,
                          maxAmount: max,
                          sortOption: draftSort,
                          customFrom: draftFrom,
                          customTo: draftTo,
                        );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    minController.dispose();
    maxController.dispose();
  }

  Widget _styledFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = AppColors.emerald.withValues(alpha: 0.24);
    final selectedBorder = AppColors.emerald.withValues(alpha: 0.75);
    final unselectedBg = isDark
        ? AppColors.darkSurfaceAlt.withValues(alpha: 0.92)
        : AppColors.lightSurfaceAlt.withValues(alpha: 0.95);
    final unselectedBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: unselectedBg,
      selectedColor: selectedBg,
      side: BorderSide(
        color: selected ? selectedBorder : unselectedBorder,
        width: selected ? 1.2 : 1,
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected
            ? (isDark ? const Color(0xFFE9F9EC) : const Color(0xFF123122))
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.86),
      ),
      onSelected: (_) => onSelected(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final filters = ref.watch(transactionFilterProvider);
    final filterController = ref.read(transactionFilterProvider.notifier);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final selectedCategoryName = filters.categoryId == null
        ? 'All categories'
        : categories
                  .where((c) => c.id == filters.categoryId)
                  .map((e) => e.name)
                  .firstOrNull ??
              'Category';
    final effectiveRange = filters.effectiveRange(DateTime.now());
    final hasActiveFilters =
        filters.type != null ||
        filters.categoryId != null ||
        filters.paymentMode != null ||
        filters.minAmount != null ||
        filters.maxAmount != null ||
        filters.searchQuery.trim().isNotEmpty ||
        filters.sortOption != TransactionSortOption.newestFirst ||
        filters.datePreset != TransactionDatePreset.thisMonth;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: filterController.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: filters.searchQuery.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () =>
                                    filterController.setSearchQuery(''),
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    if (hasActiveFilters) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (filters.datePreset !=
                              TransactionDatePreset.thisMonth)
                            InputChip(
                              label: Text(
                                filters.datePreset ==
                                        TransactionDatePreset.custom
                                    ? '${DateFormat('dd MMM').format(effectiveRange.start)} - ${DateFormat('dd MMM').format(effectiveRange.end)}'
                                    : _datePresetLabel(filters.datePreset),
                              ),
                              onDeleted: () => filterController.setDatePreset(
                                TransactionDatePreset.thisMonth,
                              ),
                            ),
                          if (filters.type != null)
                            InputChip(
                              label: Text(_typeLabel(filters.type!)),
                              onDeleted: () => filterController.setType(null),
                            ),
                          if (filters.categoryId != null)
                            InputChip(
                              label: Text(selectedCategoryName),
                              onDeleted: () =>
                                  filterController.setCategory(null),
                            ),
                          if (filters.paymentMode != null)
                            InputChip(
                              label: Text(
                                filters.paymentMode!.value.toUpperCase(),
                              ),
                              onDeleted: () => filterController.applyAdvanced(
                                paymentMode: null,
                                minAmount: filters.minAmount,
                                maxAmount: filters.maxAmount,
                                sortOption: filters.sortOption,
                                customFrom: filters.customFrom,
                                customTo: filters.customTo,
                              ),
                            ),
                          if (filters.minAmount != null)
                            InputChip(
                              label: Text(
                                'Min ${Formatters.currency(filters.minAmount!)}',
                              ),
                              onDeleted: () => filterController.applyAdvanced(
                                paymentMode: filters.paymentMode,
                                minAmount: null,
                                maxAmount: filters.maxAmount,
                                sortOption: filters.sortOption,
                                customFrom: filters.customFrom,
                                customTo: filters.customTo,
                              ),
                            ),
                          if (filters.maxAmount != null)
                            InputChip(
                              label: Text(
                                'Max ${Formatters.currency(filters.maxAmount!)}',
                              ),
                              onDeleted: () => filterController.applyAdvanced(
                                paymentMode: filters.paymentMode,
                                minAmount: filters.minAmount,
                                maxAmount: null,
                                sortOption: filters.sortOption,
                                customFrom: filters.customFrom,
                                customTo: filters.customTo,
                              ),
                            ),
                          if (filters.sortOption !=
                              TransactionSortOption.newestFirst)
                            InputChip(
                              label: Text(_sortLabel(filters.sortOption)),
                              onDeleted: () => filterController.applyAdvanced(
                                paymentMode: filters.paymentMode,
                                minAmount: filters.minAmount,
                                maxAmount: filters.maxAmount,
                                sortOption: TransactionSortOption.newestFirst,
                                customFrom: filters.customFrom,
                                customTo: filters.customTo,
                              ),
                            ),
                          ActionChip(
                            label: const Text('Clear all'),
                            onPressed: filterController.clearAll,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final preset in TransactionDatePreset.values)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: _styledFilterChip(
                                context,
                                label:
                                    preset == TransactionDatePreset.custom &&
                                        filters.datePreset ==
                                            TransactionDatePreset.custom
                                    ? '${DateFormat('dd MMM').format(effectiveRange.start)} - ${DateFormat('dd MMM').format(effectiveRange.end)}'
                                    : _datePresetLabel(preset),
                                selected: filters.datePreset == preset,
                                onSelected: () async {
                                  if (preset == TransactionDatePreset.custom) {
                                    await _pickCustomDateRange(
                                      context,
                                      ref,
                                      filters,
                                    );
                                    return;
                                  }
                                  filterController.setDatePreset(preset);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.start,
                      children: [
                        _styledFilterChip(
                          context,
                          label: 'All',
                          selected: filters.type == null,
                          onSelected: () => filterController.setType(null),
                        ),
                        _styledFilterChip(
                          context,
                          label: 'Income',
                          selected: filters.type == 'income',
                          onSelected: () => filterController.setType('income'),
                        ),
                        _styledFilterChip(
                          context,
                          label: 'Expense',
                          selected: filters.type == 'expense',
                          onSelected: () => filterController.setType('expense'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: _styledFilterChip(
                              context,
                              label: 'All',
                              selected: filters.categoryId == null,
                              onSelected: () =>
                                  filterController.setCategory(null),
                            ),
                          ),
                          ...categories.map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: _styledFilterChip(
                                context,
                                label: category.name,
                                selected: filters.categoryId == category.id,
                                onSelected: () =>
                                    filterController.setCategory(category.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openAdvancedFilters(context, ref, filters),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Advanced Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            transactions.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: Text('No transactions yet')),
                  );
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
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                              if (item.recurringRuleId != null &&
                                  item.isRecurringInstance) {
                                final action = await _pickRecurringDeleteAction(
                                  context,
                                );
                                if (action == null) return false;
                                if (action ==
                                    _RecurringDeleteAction.thisAndFuture) {
                                  await ref
                                      .read(recurringRepositoryProvider)
                                      .deleteThisAndFuture(
                                        ruleId: item.recurringRuleId!,
                                        fromDate: item.date,
                                      );
                                } else {
                                  await ref
                                      .read(transactionActionsProvider)
                                      .softDelete(item.id);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Recurring updated'),
                                    ),
                                  );
                                }
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
                                    content: const Text('Transaction deleted'),
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
                                onTap: () => _openTransactionDetail(
                                  context,
                                  ref,
                                  item,
                                  categoryName,
                                ),
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
                                  item.isRecurringInstance
                                      ? '$categoryName  🔁'
                                      : categoryName,
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
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: Text('Failed to load: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RecurringDeleteAction { onlyThis, thisAndFuture }

enum _RecurringEditAction { stop }
