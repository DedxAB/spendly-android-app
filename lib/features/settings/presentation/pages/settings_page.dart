import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/widgets/noir_header.dart';
import 'package:spendly/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';
import 'package:spendly/features/user/data/repositories/user_profile_repository_impl.dart';
import 'package:spendly/features/user/presentation/providers/user_profile_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFF0D0D0D);
    const divider = Color(0xFF2A2A2A);
    const primary = Colors.white;
    const secondary = Color(0xFFBBBBBB);
    const muted = Color(0xFF8F8F8F);

    final profile = ref.watch(userProfileProvider).valueOrNull;
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final budgetAlerts = settings?.budgetAlertsEnabled ?? true;
    final dailyReminder = settings?.dailyReminderEnabled ?? false;
    final cloudSync = ref.watch(cloudSyncControllerProvider).valueOrNull;

    final name = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()
        : 'User';
    final imageUrl = (profile?.imageUrl?.trim().isNotEmpty ?? false)
        ? profile!.imageUrl!.trim()
        : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: NoirHeader(
        showLeading: true,
        leadingIcon: Icons.arrow_back,
        onLeadingTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/home');
          }
        },
        showProfileAction: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfilePhoto(
                imageUrl: imageUrl,
                backgroundColor: const Color(0xFF323A44),
                iconColor: const Color(0xFFD9DEE3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: primary,
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Spendly profile',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const _SectionLabel('PREFERENCES', color: secondary),
          const Divider(color: divider, height: 26),
          _ProfileRow(
            icon: Icons.person,
            title: 'Account',
            onTap: () => _editAccount(context, ref),
            textColor: primary,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.shield,
            title: 'Security',
            onTap: () => _openSecurity(context, ref),
            textColor: primary,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
            textColor: primary,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.category_outlined,
            title: 'Categories',
            onTap: () => context.push('/categories'),
            textColor: primary,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.handshake_outlined,
            title: 'Lend & Borrow',
            subtitle: 'Track people and settlements',
            onTap: () => context.go('/lend'),
            textColor: primary,
            subtitleColor: muted,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.repeat,
            title: 'Recurring',
            subtitle: 'Automate repeating expenses',
            onTap: () => context.push('/recurring'),
            textColor: primary,
            subtitleColor: muted,
            iconColor: muted,
            dividerColor: divider,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('DATA & SYSTEM', color: secondary),
          const Divider(color: divider, height: 26),
          _ProfileRow(
            icon: Icons.file_download_outlined,
            title: 'Export Data',
            subtitle: 'CSV, JSON formats available',
            onTap: () => _openExport(context, ref),
            textColor: primary,
            subtitleColor: muted,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.file_upload_outlined,
            title: 'Import Data',
            subtitle: 'Import from JSON backup',
            onTap: () => _openImport(context, ref),
            textColor: primary,
            subtitleColor: muted,
            iconColor: muted,
            dividerColor: divider,
          ),
          _ProfileRow(
            icon: Icons.delete_forever_outlined,
            title: 'Erase All Data',
            subtitle: 'Reset app to a clean start',
            onTap: () => _eraseAllData(context, ref),
            textColor: primary,
            subtitleColor: muted,
            iconColor: const Color(0xFFFF8D8D),
            dividerColor: divider,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: divider),
              color: const Color(0xFF121212),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud Sync',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  cloudSync?.isConnected == true
                      ? 'Connected: ${cloudSync?.connectedEmail ?? '-'}'
                      : 'Not connected',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  cloudSync?.lastBackupAt == null
                      ? 'Last backup: never'
                      : 'Last backup: ${DateFormat('dd MMM, hh:mm a').format(cloudSync!.lastBackupAt!)}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Automatic daily backup',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: cloudSync?.automaticDailyBackup ?? false,
                  onChanged: cloudSync?.isConnected == true
                      ? (value) async {
                          await ref
                              .read(cloudSyncControllerProvider.notifier)
                              .setAutomaticDailyBackup(value);
                        }
                      : null,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: cloudSync?.isProcessing == true
                          ? null
                          : () async {
                              if (cloudSync?.isConnected == true) {
                                await ref
                                    .read(cloudSyncControllerProvider.notifier)
                                    .disconnectAccount();
                              } else {
                                await ref
                                    .read(cloudSyncControllerProvider.notifier)
                                    .connectAccount();
                              }
                            },
                      child: Text(
                        cloudSync?.isConnected == true
                            ? 'Disconnect'
                            : 'Connect',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: cloudSync?.isConnected == true
                          ? () async {
                              await ref
                                  .read(cloudSyncControllerProvider.notifier)
                                  .backupNow();
                            }
                          : null,
                      child: const Text('Backup now'),
                    ),
                    OutlinedButton(
                      onPressed: cloudSync?.isConnected == true
                          ? () async {
                              await ref
                                  .read(cloudSyncControllerProvider.notifier)
                                  .restoreFromDrive();
                            }
                          : null,
                      child: const Text('Restore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Budget alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Show in-app budget warning notifications',
              style: TextStyle(fontSize: 12),
            ),
            value: budgetAlerts,
            onChanged: (value) async {
              await ref
                  .read(settingsRepositoryProvider)
                  .setNotificationPreferences(
                    budgetAlertsEnabled: value,
                    dailyReminderEnabled: dailyReminder,
                  );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Daily reminder',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Receive a push reminder every day',
              style: TextStyle(fontSize: 12),
            ),
            value: dailyReminder,
            onChanged: (value) async {
              await ref
                  .read(settingsRepositoryProvider)
                  .setNotificationPreferences(
                    budgetAlertsEnabled: budgetAlerts,
                    dailyReminderEnabled: value,
                  );
            },
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: bg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                final p = profile;
                await ref
                    .read(userProfileRepositoryProvider)
                    .updateProfile(
                      name: p?.name ?? 'User',
                      imageUrl: p?.imageUrl,
                      email: p?.email,
                      phone: p?.phone,
                      onboardingCompleted: false,
                    );
                if (context.mounted) {
                  context.go('/splash');
                }
              },
              child: const Text(
                'LOGOUT',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Center(
            child: Text(
              'Version 2.4.0',
              style: TextStyle(color: muted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAccount(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final name = TextEditingController(text: profile?.name ?? '');
    final image = TextEditingController(text: profile?.imageUrl ?? '');
    final email = TextEditingController(text: profile?.email ?? '');
    final phone = TextEditingController(text: profile?.phone ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F0F),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 4,
                color: const Color(0xFF6A6A6A),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Account',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: image,
              decoration: const InputDecoration(labelText: 'Profile photo URL'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () async {
                      await ref
                          .read(userProfileRepositoryProvider)
                          .updateProfile(
                            name: name.text.trim(),
                            imageUrl: image.text.trim(),
                            email: email.text.trim(),
                            phone: phone.text.trim(),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSecurity(BuildContext context, WidgetRef ref) async {
    final cloud = ref.read(cloudSyncControllerProvider).valueOrNull;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Security'),
        content: Text(
          cloud?.isConnected == true
              ? 'Google backup connected: ${cloud?.connectedEmail ?? ''}'
              : 'No backup account connected.',
        ),
        actions: [
          if (cloud?.isConnected != true)
            FilledButton(
              onPressed: () => ref
                  .read(cloudSyncControllerProvider.notifier)
                  .connectAccount(),
              child: const Text('Connect Google'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openExport(BuildContext context, WidgetRef ref) async {
    final payload = await ref.read(settingsRepositoryProvider).exportJson();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(child: SelectableText(payload)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payload));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openImport(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import JSON'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: 'Paste your exported JSON here',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isEmpty) return;
              await ref.read(settingsRepositoryProvider).importJson(raw);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Import completed')));
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _eraseAllData(BuildContext context, WidgetRef ref) async {
    final shouldErase = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
          'This will permanently remove all transactions, categories, recurring rules, and lend/borrow records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (shouldErase != true) return;
    await ref.read(settingsRepositoryProvider).clearAllData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data erased')));
    context.go('/splash');
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.imageUrl,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String? imageUrl;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      color: backgroundColor,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.account_box, size: 52, color: iconColor),
            )
          : Icon(Icons.account_box, size: 52, color: iconColor),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontFamily: 'Georgia',
        fontSize: 14,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.textColor,
    required this.iconColor,
    required this.dividerColor,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;
  final Color dividerColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dividerColor)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: subtitleColor ?? iconColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }
}
