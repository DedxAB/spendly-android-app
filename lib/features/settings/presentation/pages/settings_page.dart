import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _showExportDialog(BuildContext context, String payload) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(child: SelectableText(payload)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import JSON'),
        content: TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(hintText: 'Paste export payload'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(settingsRepositoryProvider).importJson(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid import payload. Please try again.')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStreamProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionTitle('Monthly Budget'),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextFormField(
                initialValue: (settings?.monthlyBudget ?? 0).toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '${AppConstants.currencySymbol} ',
                  hintText: 'Set your monthly budget',
                ),
                onFieldSubmitted: (value) async {
                  final amount = double.tryParse(value);
                  if (amount != null) {
                    await ref.read(settingsRepositoryProvider).setBudget(amount);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Theme Mode'),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(value: AppThemeMode.system, label: Text('System')),
                  ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings?.themeMode ?? AppThemeMode.system},
                onSelectionChanged: (value) {
                  ref.read(settingsRepositoryProvider).setThemeMode(value.first.value);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Data'),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Export JSON'),
                  subtitle: const Text('Download all transactions and settings'),
                  onTap: () async {
                    final payload = await ref.read(settingsRepositoryProvider).exportJson();
                    if (context.mounted) await _showExportDialog(context, payload);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Import JSON'),
                  subtitle: const Text('Restore data from exported file content'),
                  onTap: () => _showImportDialog(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.expense),
                  title: const Text('Clear all data'),
                  subtitle: const Text('This cannot be undone'),
                  onTap: () async {
                    await ref.read(settingsRepositoryProvider).clearAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('About'),
          const GlassCard(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Spendly v1.0.0'),
              subtitle: Text('Offline-first personal finance app\nGitHub: DedxAB/spendly-android-app'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}


