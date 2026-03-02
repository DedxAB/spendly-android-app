import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/cloud_sync/domain/entities/google_profile_entity.dart';
import 'package:spendly/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';
import 'package:spendly/features/user/data/repositories/user_profile_repository_impl.dart';
import 'package:spendly/features/user/presentation/providers/user_profile_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _formatDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  Future<void> _showExportDialog(BuildContext context, String payload) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup Data'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(child: SelectableText(payload)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup data copied')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Data'),
        content: TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(hintText: 'Paste backup data'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(settingsRepositoryProvider)
                    .importJson(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import successful')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invalid import payload. Please try again.',
                      ),
                    ),
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

  Future<bool> _showRestoreConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from Drive'),
        content: const Text('This will replace your current local data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final cloudSyncAsync = ref.watch(cloudSyncControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionTitle('Profile'),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: profile?.name ?? 'User',
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      isDense: true,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onFieldSubmitted: (value) async {
                      await ref
                          .read(userProfileRepositoryProvider)
                          .updateProfile(
                            name: value,
                            imageUrl: profile?.imageUrl,
                            email: profile?.email,
                            phone: profile?.phone,
                          );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    initialValue: profile?.imageUrl,
                    decoration: InputDecoration(
                      hintText: 'Profile image URL (optional)',
                      isDense: true,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onFieldSubmitted: (value) async {
                      await ref
                          .read(userProfileRepositoryProvider)
                          .updateProfile(
                            name: profile?.name ?? 'User',
                            imageUrl: value,
                            email: profile?.email,
                            phone: profile?.phone,
                          );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Monthly Budget'),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextFormField(
                initialValue: (settings?.monthlyBudget ?? 0).toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: '${AppConstants.currencySymbol} ',
                  hintText: 'Set your monthly budget',
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onFieldSubmitted: (value) async {
                  final amount = double.tryParse(value);
                  if (amount != null) {
                    await ref
                        .read(settingsRepositoryProvider)
                        .setBudget(amount);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Cloud Sync'),
          GlassCard(
            child: cloudSyncAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Could not load Cloud Sync right now.'),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => ref
                          .read(cloudSyncControllerProvider.notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (cloudSync) {
                if (!cloudSync.isConnected) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your data will be stored in your own Google Drive.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: cloudSync.isProcessing
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(
                                          cloudSyncControllerProvider.notifier,
                                        )
                                        .connectAccount();
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Google account connected',
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not connect account. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  try {
                                    final googleProfile = await ref
                                        .read(
                                          cloudSyncControllerProvider.notifier,
                                        )
                                        .fetchGoogleProfile();
                                    if (!context.mounted ||
                                        googleProfile == null) {
                                      return;
                                    }

                                    await _applyGoogleProfile(
                                      ref: ref,
                                      currentProfileName:
                                          profile?.name ?? 'User',
                                      currentProfileEmail: profile?.email,
                                      currentProfilePhone: profile?.phone,
                                      googleProfile: googleProfile,
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profile synced from Google',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    // Connection already succeeded; ignore optional profile sync failures.
                                  }
                                },
                          icon: const _GoogleLogo(),
                          label: const Text('Connect Google Account'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_done_outlined),
                      title: Text(
                        'Connected as: ${cloudSync.connectedEmail ?? 'Google account'}',
                      ),
                      trailing: TextButton(
                        onPressed: cloudSync.isProcessing
                            ? null
                            : () async {
                                try {
                                  await ref
                                      .read(
                                        cloudSyncControllerProvider.notifier,
                                      )
                                      .disconnectAccount();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Google account disconnected',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not disconnect account. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: const Text('Disconnect'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: cloudSync.isProcessing
                                  ? null
                                  : () async {
                                      try {
                                        await ref
                                            .read(
                                              cloudSyncControllerProvider
                                                  .notifier,
                                            )
                                            .backupNow();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Backup successful',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Backup failed. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: const Text('Backup Now'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: cloudSync.isProcessing
                                  ? null
                                  : () async {
                                      final confirmed =
                                          await _showRestoreConfirmDialog(
                                            context,
                                          );
                                      if (!confirmed) {
                                        return;
                                      }

                                      try {
                                        await ref
                                            .read(
                                              cloudSyncControllerProvider
                                                  .notifier,
                                            )
                                            .restoreFromDrive();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Restore successful',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Restore failed. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: const Text('Restore from Drive'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      value: cloudSync.automaticDailyBackup,
                      onChanged: cloudSync.isProcessing
                          ? null
                          : (enabled) async {
                              try {
                                await ref
                                    .read(cloudSyncControllerProvider.notifier)
                                    .setAutomaticDailyBackup(enabled);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not update backup setting. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      title: const Text('Automatic Daily Backup'),
                    ),
                    if (cloudSync.lastBackupAt != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          0,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Last backup: ${_formatDateTime(cloudSync.lastBackupAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Data'),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Copy all app data as JSON'),
                  onTap: () async {
                    final payload = await ref
                        .read(settingsRepositoryProvider)
                        .exportJson();
                    if (context.mounted) {
                      await _showExportDialog(context, payload);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore data from backup JSON'),
                  onTap: () => _showImportDialog(context, ref),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.expense,
                  ),
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
              subtitle: Text(
                'Offline-first personal finance app\nGitHub: DedxAB/spendly-android-app',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyGoogleProfile({
    required WidgetRef ref,
    required String currentProfileName,
    required String? currentProfileEmail,
    required String? currentProfilePhone,
    required GoogleProfileEntity googleProfile,
  }) async {
    final name = (googleProfile.displayName ?? '').trim();
    await ref
        .read(userProfileRepositoryProvider)
        .updateProfile(
          name: name.isEmpty ? currentProfileName : name,
          imageUrl: googleProfile.photoUrl,
          email: googleProfile.email.isEmpty
              ? currentProfileEmail
              : googleProfile.email,
          phone: currentProfilePhone,
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

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
