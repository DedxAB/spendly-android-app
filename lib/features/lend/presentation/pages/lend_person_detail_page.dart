import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/lend/data/repositories/lend_repository_impl.dart';
import 'package:spendly/features/lend/presentation/providers/lend_provider.dart';

class LendPersonDetailPage extends ConsumerWidget {
  const LendPersonDetailPage({super.key, required this.personId});

  final String personId;

  Future<void> _showAddEntryDialog(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var selectedType = LendEntryType.lent;
    var selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<LendEntryType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: LendEntryType.lent,
                      label: Text('Lent'),
                    ),
                    ButtonSegment(
                      value: LendEntryType.borrowed,
                      label: Text('Borrowed'),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (value) {
                    setState(() => selectedType = value.first);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\u20B9 ',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(Formatters.date(selectedDate)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
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
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                await ref
                    .read(lendRepositoryProvider)
                    .addEntry(
                      personId: personId,
                      type: selectedType,
                      amount: amount,
                      date: selectedDate,
                      note: noteController.text.trim(),
                    );
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
    final people = ref.watch(lendPeopleProvider).valueOrNull ?? const [];
    final personMatches = people.where((p) => p.id == personId);
    final person = personMatches.isEmpty ? null : personMatches.first;
    final entriesAsync = ref.watch(lendEntriesByPersonProvider(personId));

    final activeEntries =
        entriesAsync.valueOrNull
            ?.where((e) => !e.isSettled && !e.isDeleted)
            .toList(growable: false) ??
        const [];
    final net = activeEntries.fold<double>(0, (sum, e) {
      if (e.type == LendEntryType.lent) return sum + e.amount;
      return sum - e.amount;
    });

    return Scaffold(
      appBar: AppBar(title: Text(person?.name ?? 'Person')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person?.name ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Net Balance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(net.abs()),
                  style: TextStyle(
                    color: net >= 0 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const GlassCard(
                  child: Text('No entries yet. Add your first entry.'),
                );
              }
              return Column(
                children: entries
                    .map((entry) {
                      final isLent = entry.type == LendEntryType.lent;
                      final color = isLent
                          ? AppColors.income
                          : AppColors.expense;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(
                              '${isLent ? 'Lent' : 'Borrowed'} ${Formatters.currency(entry.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${Formatters.date(entry.date)}${entry.note == null || entry.note!.isEmpty ? '' : ' - ${entry.note}'}',
                            ),
                            trailing: SizedBox(
                              width: 112,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: entry.isSettled
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : color.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      entry.isSettled ? 'Settled' : 'Active',
                                      style: TextStyle(
                                        color: entry.isSettled ? null : color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () async {
                                      await ref
                                          .read(lendRepositoryProvider)
                                          .setEntrySettled(
                                            entry.id,
                                            !entry.isSettled,
                                          );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        entry.isSettled
                                            ? Icons.radio_button_unchecked
                                            : Icons.check_circle,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load: $error'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: person == null
            ? null
            : () => _showAddEntryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}
