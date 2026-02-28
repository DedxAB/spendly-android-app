import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/app/app_router.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';

class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? AppThemeMode.system;

    return MaterialApp.router(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: switch (themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}

