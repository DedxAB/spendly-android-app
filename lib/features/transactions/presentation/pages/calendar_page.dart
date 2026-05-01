import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/widgets/noir_header.dart';
import 'package:spendly/features/categories/presentation/providers/categories_provider.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  late DateTime _displayMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
    final categoryById = {for (final c in categories) c.id: c.name};

    final expenseByDay = <int, double>{};
    for (final tx in all) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.year != _displayMonth.year ||
          tx.date.month != _displayMonth.month) {
        continue;
      }
      expenseByDay[tx.date.day] = (expenseByDay[tx.date.day] ?? 0) + tx.amount;
    }

    final monthlyTotal = expenseByDay.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final selectedItems =
        all
            .where((tx) => tx.type == TransactionType.expense)
            .where((tx) => _isSameDay(tx.date, _selectedDate))
            .toList(growable: false)
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final selectedTotal = selectedItems.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );
    final visibleDays = _buildVisibleDays(_displayMonth);

    return Scaffold(
      appBar: NoirHeader(
        showLeading: true,
        leadingIcon: Icons.arrow_back,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_displayMonth),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MonthNav(
                onPrev: () => setState(
                  () => _displayMonth = DateTime(
                    _displayMonth.year,
                    _displayMonth.month - 1,
                    1,
                  ),
                ),
                onNext: () => setState(
                  () => _displayMonth = DateTime(
                    _displayMonth.year,
                    _displayMonth.month + 1,
                    1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDark),
          const SizedBox(height: 14),
          Text(
            'TOTAL SPENDING',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(monthlyTotal),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _MonthGrid(
            visibleDays: visibleDays,
            displayMonth: _displayMonth,
            selectedDate: _selectedDate,
            expenseByDay: expenseByDay,
            onTapDay: (day) => setState(() => _selectedDate = day),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM d').format(_selectedDate),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _currency.format(selectedTotal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.borderDark),
          const SizedBox(height: 10),
          if (selectedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No spending transactions on this date'),
            )
          else
            ...selectedItems.map(
              (tx) => _CalendarTransactionRow(
                title: tx.note?.trim().isNotEmpty == true
                    ? tx.note!.trim()
                    : (categoryById[tx.categoryId] ?? tx.categoryId),
                subtitle: (categoryById[tx.categoryId] ?? tx.categoryId)
                    .toUpperCase(),
                amount: tx.amount,
                icon: _iconFor(categoryById[tx.categoryId] ?? tx.categoryId),
              ),
            ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  static List<DateTime> _buildVisibleDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final sundayBasedIndex = firstOfMonth.weekday % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: sundayBasedIndex));
    return List.generate(35, (index) {
      final day = gridStart.add(Duration(days: index));
      return DateTime(day.year, day.month, day.day);
    });
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({required this.onPrev, required this.onNext});

  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Row(
        children: [
          InkWell(
            onTap: onPrev,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.chevron_left, size: 24),
            ),
          ),
          Container(width: 1, height: 44, color: Colors.white),
          InkWell(
            onTap: onNext,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.chevron_right, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleDays,
    required this.displayMonth,
    required this.selectedDate,
    required this.expenseByDay,
    required this.onTapDay,
  });

  final List<DateTime> visibleDays;
  final DateTime displayMonth;
  final DateTime selectedDate;
  final Map<int, double> expenseByDay;
  final ValueChanged<DateTime> onTapDay;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in weekdays)
                Expanded(
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.white),
                        bottom: BorderSide(color: Colors.white),
                      ),
                    ),
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final day = visibleDays[index];
              final isCurrentMonth =
                  day.month == displayMonth.month &&
                  day.year == displayMonth.year;
              final isSelected =
                  day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final double spend = isCurrentMonth
                  ? (expenseByDay[day.day] ?? 0.0)
                  : 0.0;

              return InkWell(
                onTap: () => onTapDay(day),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE5E5E5) : Colors.black,
                    border: Border.all(color: Colors.white),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.black
                              : (isCurrentMonth
                                    ? Colors.white
                                    : const Color(0xFF4A4A4A)),
                        ),
                      ),
                      const Spacer(),
                      if (spend > 0)
                        Text(
                          _shortCurrency(spend),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _shortCurrency(double amount) {
    if (amount >= 100000) {
      return '${AppConstants.currencySymbol} ${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${AppConstants.currencySymbol} ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return _currency.format(amount);
  }
}

class _CalendarTransactionRow extends StatelessWidget {
  const _CalendarTransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB9B9B9),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currency.format(amount),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

