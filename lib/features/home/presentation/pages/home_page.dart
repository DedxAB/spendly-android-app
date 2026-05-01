import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/utils/formatters.dart';
import 'package:spendly/core/widgets/noir_header.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/home/presentation/providers/home_provider.dart';
import 'package:spendly/features/lend/presentation/providers/lend_provider.dart';
import 'package:spendly/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:spendly/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:spendly/features/user/presentation/providers/user_profile_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final todaySpent = ref.watch(todaySpentProvider).valueOrNull ?? 0;
    final recent = ref.watch(recentTransactionsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final lendOverview = ref.watch(lendOverviewProvider);
    final recurringRules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final categoryById = {for (final c in categories) c.id: c.name};
    final cardholderName = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()
        : 'User';

    return Scaffold(
      appBar: NoirHeader(
        showLeading: true,
        leadingIcon: Icons.notifications_none_rounded,
        onLeadingTap: () => context.push('/notifications'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddExpenseSheet(context),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add, size: 32),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        children: [
          summary.when(
            data: (data) => _BalanceCard(
              balance: data.currentBalance,
              name: cardholderName,
            ),
            loading: () => const SizedBox(
              height: 260,
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text('Failed to load: $e'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  title: "TODAY'S\nSPEND",
                  amount: Formatters.currency(todaySpent),
                  note: '-12% vs\nyesterday',
                  noteColor: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: summary.when(
                  data: (data) => _StatTile(
                    title: 'REMAINING',
                    amount: Formatters.currency(data.remainingBudget),
                    note:
                        'of ${Formatters.currency(data.remainingBudget + data.monthlyExpense)} limit',
                    active: true,
                    noteColor: const Color(0xFF57F28F),
                  ),
                  loading: () => const _StatTile(
                    title: 'REMAINING',
                    amount: '...',
                    note: '',
                    active: true,
                  ),
                  error: (_, __) => const _StatTile(
                    title: 'REMAINING',
                    amount: '--',
                    note: '',
                    active: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          lendOverview.when(
            data: (lend) => _LendQuickCard(
              toReceive: lend.totalToReceive,
              toPay: lend.totalToPay,
              openPeople: lend.peopleBalances
                  .where((p) => p.activeEntryCount > 0)
                  .length,
              onTap: () => context.push('/lend'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (recurringRules.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.push('/recurring'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0B),
                  border: Border.all(color: const Color(0xFF242424)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${recurringRules.where((r) => r.isActive).length} active recurring rules',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB2B2B2)),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text('VIEW ALL'),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.borderDark),
          recent.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No transactions yet'),
                );
              }
              return Column(
                children: items
                    .map(
                      (tx) => _TransactionRow(
                        title: categoryById[tx.categoryId] ?? tx.categoryId,
                        subtitle: _subtitle(tx),
                        amount: tx.amount,
                        isIncome: tx.type == TransactionType.income,
                        icon: _iconFor(
                          categoryById[tx.categoryId] ?? tx.categoryId,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load: $e'),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String text) {
    final t = text.toLowerCase();
    if (t.contains('food') ||
        t.contains('dining') ||
        t.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (t.contains('uber') || t.contains('transport') || t.contains('taxi')) {
      return Icons.directions_car;
    }
    if (t.contains('shop') || t.contains('store')) {
      return Icons.shopping_bag;
    }
    if (t.contains('travel') || t.contains('flight') || t.contains('air')) {
      return Icons.flight;
    }
    if (t.contains('salary') ||
        t.contains('income') ||
        t.contains('transfer')) {
      return Icons.payments;
    }
    return Icons.receipt_long;
  }

  static String _subtitle(dynamic tx) {
    final now = DateTime.now();
    final d = tx.date as DateTime;
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(d)}';
    }
    return Formatters.date(d);
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.name});

  final double balance;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D0D), Color(0xFF171717), Color(0xFF090909)],
        ),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFF313131)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB2B2B2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.currency(balance),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'SPENDLY',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              const Text(
                'BLACK',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  border: Border.all(color: const Color(0xFF8D8D8D)),
                ),
                child: const Icon(Icons.contactless_rounded, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '.... .... .... 4092',
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 2.8,
              color: Color(0xFFE8E8E8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'CARDHOLDER\n${name.toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFFB2B2B2),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              const Text(
                'EXPIRES\n12/28',
                style: TextStyle(
                  color: Color(0xFFB2B2B2),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.amount,
    required this.note,
    this.active = false,
    this.noteColor = const Color(0xFFA3A3A3),
  });

  final String title;
  final String amount;
  final String note;
  final bool active;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active)
            const Divider(height: 0, thickness: 2, color: Colors.white),
          if (active) const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              letterSpacing: 1.6,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(
              color: noteColor,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2B2B2B)),
            ),
            child: Icon(icon, size: 23, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB2B2B2),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Formatters.currency(amount)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isIncome ? const Color(0xFF57F28F) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LendQuickCard extends StatelessWidget {
  const _LendQuickCard({
    required this.toReceive,
    required this.toPay,
    required this.openPeople,
    required this.onTap,
  });

  final double toReceive;
  final double toPay;
  final int openPeople;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          border: Border.all(color: const Color(0xFF242424)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.handshake_outlined, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'LEND & BORROW',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LendMetric(
                    label: 'You Receive',
                    value: Formatters.currency(toReceive),
                    valueColor: const Color(0xFF57F28F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LendMetric(
                    label: 'You Owe',
                    value: Formatters.currency(toPay),
                    valueColor: const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$openPeople active people - Tap to open',
              style: const TextStyle(
                color: Color(0xFFB2B2B2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LendMetric extends StatelessWidget {
  const _LendMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFA3A3A3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

