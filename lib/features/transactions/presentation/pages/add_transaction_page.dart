import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/features/categories/presentation/pages/categories_page.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _paymentMode = existing.paymentMode;
      _date = existing.date;
      _selectedCategoryId = existing.categoryId;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _noteController.text = existing.note ?? '';
    } else {
      _type = TransactionType.expense;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category.')));
      return;
    }

    final amount = double.parse(_amountController.text);
    final now = DateTime.now();
    final entity = TransactionEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      type: _type,
      amount: amount,
      categoryId: _selectedCategoryId!,
      paymentMode: _paymentMode,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: _date,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      isDeleted: false,
    );

    final actions = ref.read(transactionActionsProvider);
    if (widget.existing == null) {
      await actions.save(entity);
    } else {
      await actions.update(entity);
    }

    HapticFeedback.lightImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryByTypeProvider(_type.name));

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Transaction' : 'Edit Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.income, label: Text('Income')),
                    ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) => setState(() {
                    _type = value.first;
                    _selectedCategoryId = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _amountController,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${AppConstants.currencySymbol} ',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesPage())),
                          child: const Text('Manage'),
                        ),
                      ],
                    ),
                    categories.when(
                      data: (items) {
                        if (items.isEmpty) return const Text('No categories available for this type.');
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: items
                              .map(
                                (item) => ChoiceChip(
                                  label: Text(item.name),
                                  selected: _selectedCategoryId == item.id,
                                  onSelected: (_) => setState(() => _selectedCategoryId = item.id),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Failed to load categories: $error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment mode', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PaymentMode.values
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(mode.name.toUpperCase()),
                              selected: _paymentMode == mode,
                              onSelected: (_) => setState(() => _paymentMode = mode),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(Formatters.date(_date)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: _date,
                        );
                        if (selected != null) setState(() => _date = selected);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
}
