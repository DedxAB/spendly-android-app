import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _showExportDialog(BuildContext context, String payload) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: SelectableText(payload))),
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
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: (settings?.monthlyBudget ?? 0).toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(prefixText: '${AppConstants.currencySymbol} '),
                    onFieldSubmitted: (value) async {
                      final amount = double.tryParse(value);
                      if (amount != null) {
                        await ref.read(settingsRepositoryProvider).setBudget(amount);
                      }
                    },
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
                  Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(value: AppThemeMode.system, label: Text('System')),
                      ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {settings?.themeMode ?? AppThemeMode.system},
                    onSelectionChanged: (value) {
                      ref.read(settingsRepositoryProvider).setThemeMode(value.first.name);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Export JSON'),
                  onTap: () async {
                    final payload = await ref.read(settingsRepositoryProvider).exportJson();
                    if (context.mounted) {
                      await _showExportDialog(context, payload);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline),
                  title: const Text('Import JSON'),
                  onTap: () => _showImportDialog(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear all data'),
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
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              title: Text('About'),
              subtitle: Text('Spendly v1.0.0\nOpen-source ready personal finance app'),
            ),
          ),
        ],
      ),
    );
  }
}
