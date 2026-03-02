import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/lend/data/repositories/lend_repository_impl.dart';
import 'package:spendly/features/lend/presentation/providers/lend_provider.dart';

class LendPage extends ConsumerWidget {
  const LendPage({super.key});

  Future<void> _showAddPersonDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Person'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Person name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await ref.read(lendRepositoryProvider).addPerson(name);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(lendOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lend'),
        actions: [
          IconButton(
            onPressed: () => _showAddPersonDialog(context, ref),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: overview.when(
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetric(
                            label: 'You Will Receive',
                            value: Formatters.currency(data.totalToReceive),
                            color: AppColors.income,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryMetric(
                            label: 'You Owe',
                            value: Formatters.currency(data.totalToPay),
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('People', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (data.peopleBalances.isEmpty)
                const GlassCard(
                  child: Text(
                    'No people added yet. Tap + to add your first person.',
                  ),
                ),
              ...data.peopleBalances.map((item) {
                final isPositive = item.netBalance >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => context.push('/lend/${item.person.id}'),
                      title: Text(
                        item.person.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${item.activeEntryCount} active entries'),
                      trailing: Text(
                        Formatters.currency(item.netBalance.abs()),
                        style: TextStyle(
                          color: isPositive
                              ? AppColors.income
                              : AppColors.expense,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPersonDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: color.withValues(alpha: 0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
