import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:spendly/features/home/presentation/pages/home_page.dart';
import 'package:spendly/features/insights/presentation/pages/insights_page.dart';
import 'package:spendly/features/lend/presentation/pages/lend_page.dart';
import 'package:spendly/features/lend/presentation/pages/lend_person_detail_page.dart';
import 'package:spendly/features/settings/presentation/pages/settings_page.dart';
import 'package:spendly/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spendly/features/transactions/presentation/pages/transactions_page.dart';
import 'package:spendly/features/user/presentation/pages/profile_onboarding_page.dart';
import 'package:spendly/features/user/presentation/providers/user_profile_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const ProfileOnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsPage(),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsPage(),
          ),
          GoRoute(path: '/lend', builder: (context, state) => const LendPage()),
        ],
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) {
          final rawType = state.uri.queryParameters['type'];
          final initialType = switch (rawType) {
            'income' => TransactionType.income,
            'expense' => TransactionType.expense,
            _ => null,
          };
          return AddTransactionPage(initialType: initialType);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/lend/:personId',
        builder: (context, state) =>
            LendPersonDetailPage(personId: state.pathParameters['personId']!),
      ),
    ],
  );
});

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    // Fire-and-forget so cloud sync checks never block splash navigation.
    ref.read(cloudSyncRepositoryProvider).runDailyBackupIfNeeded();
    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;
    if (profile.onboardingCompleted) {
      context.go('/home');
      return;
    }
    context.go('/onboarding/profile');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/spendly_splash.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/lend')) return 3;
    if (location.startsWith('/insights')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    const items = [
      _ShellNavItem(
        icon: CupertinoIcons.home,
        selectedIcon: CupertinoIcons.house_fill,
      ),
      _ShellNavItem(
        icon: CupertinoIcons.square_list,
        selectedIcon: CupertinoIcons.square_list_fill,
      ),
      _ShellNavItem(
        icon: CupertinoIcons.add,
        selectedIcon: CupertinoIcons.add,
        isCenterAction: true,
      ),
      _ShellNavItem(
        icon: CupertinoIcons.person_2,
        selectedIcon: CupertinoIcons.person_2_fill,
      ),
      _ShellNavItem(
        icon: CupertinoIcons.chart_pie,
        selectedIcon: CupertinoIcons.chart_pie_fill,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const _GlobalBackground(),
          Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              canvasColor: Colors.transparent,
            ),
            child: child,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.lightSurface.withValues(alpha: 0.96),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.emerald.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _ShellNavTile(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () {
                      if (i == 0) {
                        context.go('/home');
                        return;
                      }
                      if (i == 1) {
                        context.go('/transactions');
                        return;
                      }
                      if (i == 2) {
                        context.push('/transactions/new');
                        return;
                      }
                      if (i == 3) {
                        context.go('/lend');
                        return;
                      }
                      if (i == 4) {
                        context.go('/insights');
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalBackground extends StatelessWidget {
  const _GlobalBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [const Color(0xFF1C3B34), AppColors.darkBackground]
        : [const Color(0xFFEAF6EC), const Color(0xFFDCEEE0)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -70,
            child: _GlowOrb(
              size: 260,
              color: AppColors.emerald.withValues(alpha: isDark ? 0.24 : 0.14),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: _GlowOrb(
              size: 220,
              color: AppColors.emerald.withValues(alpha: isDark ? 0.16 : 0.12),
            ),
          ),
          Positioned(
            top: 190,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              color: AppColors.emerald.withValues(alpha: isDark ? 0.10 : 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.icon,
    required this.selectedIcon,
    this.isCenterAction = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool isCenterAction;
}

class _ShellNavTile extends StatelessWidget {
  const _ShellNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ShellNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = selected
        ? AppColors.emerald
        : onSurface.withValues(alpha: 0.42);

    if (item.isCenterAction) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.emerald,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(
                      alpha: isDark ? 0.24 : 0.18,
                    ),
                    blurRadius: isDark ? 12 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Color(0xFF1A1433),
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.06);
            }
            return null;
          }),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? AppColors.emerald.withValues(alpha: 0.14)
                      : Colors.transparent,
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 23,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
