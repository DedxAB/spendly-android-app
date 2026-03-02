import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/categories/presentation/pages/categories_page.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:uuid/uuid.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.existing});

  final TransactionEntity? existing;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _date = DateTime.now();
  String? _selectedCategoryId;
  RecurringFrequency? _selectedRepeat;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _paymentMode = existing.paymentMode;
      _date = existing.date;
      _selectedCategoryId = existing.categoryId;
      _selectedRepeat = null;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _noteController.text = existing.note ?? '';
    } else {
      _type = TransactionType.expense;
      _selectedRepeat = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final now = DateTime.now();
    String? recurringRuleId = widget.existing?.recurringRuleId;
    var isRecurringInstance = widget.existing?.isRecurringInstance ?? false;
    var createdRecurringRule = false;

    if (widget.existing == null && _selectedRepeat != null) {
      final allCategories = ref.read(allCategoriesProvider).valueOrNull;
      final filtered = allCategories
          ?.where((category) => category.id == _selectedCategoryId)
          .toList(growable: false);
      final matched = (filtered != null && filtered.isNotEmpty)
          ? filtered.first
          : null;
      final categoryName =
          matched?.name ??
          (_type == TransactionType.income ? 'Income' : 'Expense');
      recurringRuleId = const Uuid().v4();
      final rule = RecurringRuleEntity(
        id: recurringRuleId,
        title: categoryName,
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId!,
        paymentMode: _paymentMode,
        frequency: _selectedRepeat!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        startDate: _date,
        nextDueDate: _advanceDate(_date, _selectedRepeat!),
        createdAt: now,
        updatedAt: now,
        isActive: true,
        isDeleted: false,
      );
      await ref.read(recurringRepositoryProvider).addOrUpdate(rule);
      isRecurringInstance = true;
      createdRecurringRule = true;
    }

    final entity = TransactionEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      type: _type,
      amount: amount,
      categoryId: _selectedCategoryId!,
      paymentMode: _paymentMode,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      date: _date,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      recurringRuleId: recurringRuleId,
      isRecurringInstance: isRecurringInstance,
      isDeleted: false,
    );

    final actions = ref.read(transactionActionsProvider);
    if (widget.existing == null) {
      await actions.save(entity);
    } else {
      await actions.update(entity);
    }
    if (createdRecurringRule) {
      await ref.read(recurringRepositoryProvider).processDueRules();
    }

    HapticFeedback.lightImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryByTypeProvider(_type.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Transaction' : 'Edit Transaction',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SegmentedButton<TransactionType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) => setState(() {
                    _type = value.first;
                    _selectedCategoryId = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextFormField(
                  controller: _amountController,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${AppConstants.currencySymbol} ',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0)
                      return 'Enter a valid amount';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoriesPage(),
                            ),
                          ),
                          child: const Text('Manage'),
                        ),
                      ],
                    ),
                    categories.when(
                      data: (items) {
                        if (items.isEmpty)
                          return const Text(
                            'No categories available for this type.',
                          );
                        return Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: items
                              .map(
                                (item) => FilterChip(
                                  avatar: const Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                  ),
                                  label: Text(item.name),
                                  selected: _selectedCategoryId == item.id,
                                  onSelected: (_) => setState(
                                    () => _selectedCategoryId = item.id,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) =>
                          Text('Failed to load categories: $error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Mode',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        _modeChip('Cash', PaymentMode.cash),
                        _modeChip('UPI', PaymentMode.upi),
                        _modeChip('Card', PaymentMode.card),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(Formatters.date(_date)),
                      trailing: const Icon(Icons.calendar_month_outlined),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          initialDate: _date,
                        );
                        if (selected != null) setState(() => _date = selected);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Repeat'),
                      subtitle: Text(
                        widget.existing?.recurringRuleId != null
                            ? 'Manage in transaction detail'
                            : _repeatLabel(_selectedRepeat),
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: widget.existing != null
                          ? null
                          : () => _pickRepeatFrequency(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, PaymentMode mode) {
    return ChoiceChip(
      label: Text(label),
      selected: _paymentMode == mode,
      onSelected: (_) => setState(() => _paymentMode = mode),
    );
  }

  String _repeatLabel(RecurringFrequency? frequency) {
    if (frequency == null) return 'None';
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

  Future<void> _pickRepeatFrequency(BuildContext context) async {
    final selected = await showModalBottomSheet<RecurringFrequency?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Does not repeat'),
                trailing: _selectedRepeat == null
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(null),
              ),
              ListTile(
                title: const Text('Daily'),
                trailing: _selectedRepeat == RecurringFrequency.daily
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.daily),
              ),
              ListTile(
                title: const Text('Weekly'),
                trailing: _selectedRepeat == RecurringFrequency.weekly
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.weekly),
              ),
              ListTile(
                title: const Text('Monthly'),
                trailing: _selectedRepeat == RecurringFrequency.monthly
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.monthly),
              ),
              ListTile(
                title: const Text('Yearly'),
                trailing: _selectedRepeat == RecurringFrequency.yearly
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(RecurringFrequency.yearly),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _selectedRepeat = selected);
  }

  DateTime _advanceDate(DateTime date, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurringFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}
