import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:uuid/uuid.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  static IconData _iconForCategory(String name, TransactionType type) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('dining') || n.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (n.contains('grocery')) return Icons.local_grocery_store;
    if (n.contains('travel') || n.contains('flight')) return Icons.flight;
    if (n.contains('transport') || n.contains('taxi') || n.contains('uber')) {
      return Icons.directions_car;
    }
    if (n.contains('shopping') || n.contains('shop')) return Icons.shopping_bag;
    if (n.contains('rent') || n.contains('home')) return Icons.home;
    if (n.contains('bill') || n.contains('utility') || n.contains('electric')) {
      return Icons.receipt_long;
    }
    if (n.contains('health') || n.contains('medical')) return Icons.local_hospital;
    if (n.contains('education') || n.contains('study')) return Icons.school;
    if (n.contains('entertainment') || n.contains('movie')) return Icons.movie;
    if (n.contains('gift')) return Icons.card_giftcard;
    if (n.contains('salary') || n.contains('income')) return Icons.payments;
    if (n.contains('freelance') || n.contains('business')) return Icons.work;
    if (n.contains('investment')) return Icons.trending_up;
    return type == TransactionType.income ? Icons.south_west : Icons.north_east;
  }

  Future<void> _showCategoryDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    TransactionType type = TransactionType.expense;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TransactionType>(
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
                selected: {type},
                onSelectionChanged: (selection) =>
                    setState(() => type = selection.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final now = DateTime.now();
                final category = CategoryEntity(
                  id: const Uuid().v4(),
                  name: name,
                  icon: 'category',
                  color: '#00A88F',
                  type: type,
                  createdAt: now,
                  updatedAt: now,
                );
                await ref.read(categoriesRepositoryProvider).add(category);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    final bg = Colors.black;
    final surface = const Color(0xFF0F0F0F);
    final border = const Color(0xFF2E2E2E);
    final primary = Colors.white;
    final secondary = const Color(0xFFB0B0B0);
    const destructive = Color(0xFFE35D5D);
    const destructiveBorder = Color(0xFF5A2323);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: bg,
        foregroundColor: primary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        backgroundColor: primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: categories.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No categories available',
                style: TextStyle(color: secondary),
              ),
            );
          }
          final expenses = items
              .where((e) => e.type == TransactionType.expense)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          final incomes = items
              .where((e) => e.type == TransactionType.income)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: expenses.length + incomes.length + 2,
            itemBuilder: (context, index) {
              final expenseHeaderIndex = 0;
              final expenseStart = 1;
              final incomeHeaderIndex = expenseStart + expenses.length;
              final incomeStart = incomeHeaderIndex + 1;

              if (index == expenseHeaderIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'EXPENSE',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                );
              }
              if (index == incomeHeaderIndex) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 10),
                  child: Text(
                    'INCOME',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                );
              }

              final category = index < incomeHeaderIndex
                  ? expenses[index - expenseStart]
                  : incomes[index - incomeStart];
              final icon = _iconForCategory(category.name, category.type);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border.all(color: border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
                    ),
                    child: Icon(icon, color: primary, size: 20),
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    category.type.name.toUpperCase(),
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      letterSpacing: 0.9,
                    ),
                  ),
                  trailing: InkWell(
                    onTap: () => ref
                        .read(categoriesRepositoryProvider)
                        .softDelete(category.id),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: destructiveBorder),
                        color: const Color(0x221B0000),
                      ),
                      child: const Icon(
                        Icons.delete_sweep_outlined,
                        color: destructive,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
