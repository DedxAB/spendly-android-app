import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/app/app_router.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/recurring/presentation/providers/recurring_provider.dart';

class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(recurringBootstrapProvider);
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
