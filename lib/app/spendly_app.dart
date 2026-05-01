import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/app/app_router.dart';
import 'package:spendly/core/notifications/local_notification_service.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/home/presentation/providers/home_provider.dart';
import 'package:spendly/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';

class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(recurringBootstrapProvider);
    ref.listen(settingsStreamProvider, (previous, next) async {
      final settings = next.valueOrNull;
      if (settings == null) return;
      final notifications = ref.read(localNotificationServiceProvider);
      await notifications.initialize();
      if (settings.dailyReminderEnabled) {
        await notifications.scheduleDailyReminder();
      } else {
        await notifications.cancelDailyReminder();
      }
    });
    ref.listen(dashboardSummaryProvider, (previous, next) async {
      final summary = next.valueOrNull;
      final settings = ref.read(settingsStreamProvider).valueOrNull;
      if (summary == null || settings == null) return;
      if (!settings.budgetAlertsEnabled) return;
      if (summary.remainingBudget >= 0) return;
      final now = DateTime.now();
      final last = settings.lastBudgetAlertAt;
      final alreadySentToday =
          last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;
      if (alreadySentToday) return;
      await ref
          .read(localNotificationServiceProvider)
          .showBudgetAlert(summary.remainingBudget.abs());
      await ref.read(settingsRepositoryProvider).markBudgetAlertNotified(now);
    });
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
