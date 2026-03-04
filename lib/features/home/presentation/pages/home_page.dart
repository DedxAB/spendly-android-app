import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/glass_card.dart';
import 'package:spendly/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:spendly/features/home/presentation/providers/home_provider.dart';
import 'package:spendly/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:spendly/features/user/presentation/providers/user_profile_provider.dart';
import 'package:uuid/uuid.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _openQuickAdd(BuildContext context, WidgetRef ref) async {
    final categories = await ref
        .read(categoriesRepositoryProvider)
        .watchByType(TransactionType.expense.value)
        .first;
    if (!context.mounted) return;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create an expense category first.')),
      );
      return;
    }

    final amountController = TextEditingController();
    CategoryEntity selectedCategory = categories.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Add Expense',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  prefixText: '\u20B9 ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c.name),
                        selected: selectedCategory.id == c.id,
                        onSelected: (_) => setState(() => selectedCategory = c),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) return;

                    final now = DateTime.now();
                    final tx = TransactionEntity(
                      id: const Uuid().v4(),
                      type: TransactionType.expense,
                      amount: amount,
                      categoryId: selectedCategory.id,
                      paymentMode: PaymentMode.upi,
                      note: null,
                      date: now,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await ref.read(transactionsRepositoryProvider).add(tx);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expense added'),
                          duration: Duration(milliseconds: 900),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = ref.watch(dashboardSummaryProvider);
    final todaySpent = ref.watch(todaySpentProvider).valueOrNull ?? 0;
    final recent = ref.watch(recentTransactionsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final cloudSync = ref.watch(cloudSyncControllerProvider).valueOrNull;
    final name = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()
        : 'User';
    final profileImageUrl = (profile?.imageUrl?.trim().isNotEmpty ?? false)
        ? profile!.imageUrl!.trim()
        : null;
    final isGoogleConnected = cloudSync?.isConnected ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _ProfileAvatar(
              name: name,
              imageUrl: isGoogleConnected ? profileImageUrl : null,
              connectedToGoogle: isGoogleConnected,
            ),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          24,
        ),
        children: [
          Text(
            '${_greetingText()}, $name',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your financial overview',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickAddCard(onTap: () => _openQuickAdd(context, ref)),
          const SizedBox(height: AppSpacing.md),
          summary.when(
            data: (data) => _HeroBalanceCard(
              balance: data.currentBalance,
              income: data.monthlyIncome,
              expense: data.monthlyExpense,
              remainingBudget: data.remainingBudget,
            ),
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) =>
                GlassCard(child: Text('Failed to load: $error')),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          summary.when(
            data: (data) {
              final savingsPct = data.monthlyIncome <= 0
                  ? 0.0
                  : ((data.monthlyIncome - data.monthlyExpense) /
                            data.monthlyIncome) *
                        100;
              return SizedBox(
                height: 188,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatPill(
                      title: 'Today Spent',
                      value: Formatters.currency(todaySpent),
                      color: AppColors.expense,
                      icon: Icons.north_east_rounded,
                    ),
                    _StatPill(
                      title: 'Remaining Budget',
                      value: Formatters.currency(data.remainingBudget),
                      color: data.remainingBudget < 0
                          ? AppColors.expense
                          : AppColors.emerald,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _StatPill(
                      title: 'Savings %',
                      value: '${savingsPct.toStringAsFixed(1)}%',
                      color: savingsPct < 0
                          ? AppColors.expense
                          : AppColors.income,
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 96),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          recent.when(
            data: (items) {
              if (items.isEmpty) {
                return const GlassCard(
                  child: Text(
                    'No transactions yet. Add your first transaction.',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? const [
                                        Color(0xFF1A2E2A),
                                        Color(0xFF152722),
                                        Color(0xFF10201C),
                                      ]
                                    : const [
                                        Color(0xFFF8FCFA),
                                        Color(0xFFEEF6F1),
                                        Color(0xFFE6F0EA),
                                      ],
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : Colors.black.withValues(alpha: 0.10),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              leading: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.20)
                                      : const Color(0xFFDDE9E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  e.type == TransactionType.income
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  color: e.type == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                              title: Text(
                                e.note?.isNotEmpty == true
                                    ? e.note!
                                    : e.categoryId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                Formatters.date(e.date),
                                style: TextStyle(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.72)
                                      : const Color(0xFF31473D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                Formatters.currency(e.amount),
                                style: TextStyle(
                                  color: e.type == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load: $error'),
          ),
        ],
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.imageUrl,
    required this.connectedToGoogle,
  });

  final String name;
  final String? imageUrl;
  final bool connectedToGoogle;

  @override
  Widget build(BuildContext context) {
    final hasGooglePhoto = connectedToGoogle && imageUrl != null;
    if (hasGooglePhoto) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: _fallbackColor(name),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _fallbackColor(String seed) {
    final colors = <Color>[
      const Color(0xFF1F8A70),
      const Color(0xFF2D6A9F),
      const Color(0xFFB26A00),
      const Color(0xFF8C4A8B),
      const Color(0xFF2E7D32),
      const Color(0xFFAA3A3A),
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add expense in seconds',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 52),
              backgroundColor: AppColors.emerald,
            ),
            child: const Text(
              '+\u20B9',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.remainingBudget,
  });

  final double balance;
  final double income;
  final double expense;
  final double remainingBudget;

  @override
  Widget build(BuildContext context) {
    final maskedIncome = 'INCOME ${income.toStringAsFixed(0)} XXXX';
    final maskedExpense = 'EXPENSE ${expense.toStringAsFixed(0)} XXXX';

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 196),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF97E59A), Color(0xFF6FCF76)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF74D67A).withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Balance',
                    style: TextStyle(
                      color: Color(0xFF163321),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'SPENDLY',
                    style: TextStyle(
                      color: Color(0xFF163321),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                Formatters.currency(balance),
                style: const TextStyle(
                  color: Color(0xFF102417),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maskedIncome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A3B25),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    maskedExpense,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A3B25),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Remaining Budget: ${Formatters.currency(remainingBudget)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: remainingBudget < 0 ? AppColors.expense : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF75807C), Color(0xFF58645F), Color(0xFF405047)]
              : const [Color(0xFFF7FCF8), Color(0xFFEAF4EE), Color(0xFFE2EEE7)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.10),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.20)
                  : const Color(0xFFDDE9E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF3C564B),
              size: 22,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.78)
                  : const Color(0xFF3A5248),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
