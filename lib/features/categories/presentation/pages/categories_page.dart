import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:uuid/uuid.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

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
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.income, label: Text('Income')),
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ],
                selected: {type},
                onSelectionChanged: (selection) => setState(() => type = selection.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showCategoryDialog(context, ref), child: const Icon(Icons.add)),
      body: categories.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No categories available'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final category = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.category)),
                  title: Text(category.name),
                  subtitle: Text(category.type.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(categoriesRepositoryProvider).softDelete(category.id),
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

