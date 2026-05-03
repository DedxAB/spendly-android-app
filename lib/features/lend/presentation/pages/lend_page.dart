import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/core/widgets/noir_header.dart';
import 'package:spendly/features/lend/data/repositories/lend_repository_impl.dart';
import 'package:spendly/features/lend/presentation/providers/lend_provider.dart';

class LendPage extends ConsumerWidget {
  const LendPage({super.key});

  Future<void> _confirmDeletePerson(
    BuildContext context,
    WidgetRef ref, {
    required String personId,
    required String personName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text(
          'Delete $personName and all related lend/borrow entries?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await ref.read(lendRepositoryProvider).deletePerson(personId);
  }

  Future<void> _showAddPersonDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Theme(
        data: Theme.of(dialogContext).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Color(0xFF0F0F0F),
            onSurface: Colors.white,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF2E2E2E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF2E2E2E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFFBDBDBD)),
            ),
          ),
          dialogTheme: const DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            backgroundColor: Color(0xFF0F0F0F),
          ),
        ),
        child: AlertDialog(
          title: const Text(
            'Add Person',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
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
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(lendOverviewProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: NoirHeader(
        showLeading: true,
        leadingIcon: Icons.arrow_back,
        onLeadingTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        },
        showProfileAction: false,
      ),
      body: overview.when(
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lend & Borrow',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAddPersonDialog(context, ref),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('ADD'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
              const Text(
                'People',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text('${item.activeEntryCount} active entries'),
                      trailing: SizedBox(
                        width: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                '${item.netBalance >= 0 ? '+' : '-'}${Formatters.currency(item.netBalance.abs())}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPositive
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              onSelected: (value) async {
                                if (value != 'delete') return;
                                await _confirmDeletePerson(
                                  context,
                                  ref,
                                  personId: item.person.id,
                                  personName: item.person.name,
                                );
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete person'),
                                ),
                              ],
                            ),
                          ],
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
        label: const Text('ADD PERSON'),
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
        borderRadius: BorderRadius.zero,
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
