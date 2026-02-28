import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/home/domain/entities/dashboard_summary.dart';
import 'package:spendly/features/settings/presentation/providers/settings_provider.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final totals = ref.watch(monthlyTotalsProvider);
  final settings = ref.watch(settingsStreamProvider);

  return totals.whenData((map) {
    final budget = settings.valueOrNull?.monthlyBudget ?? 0;
    final income = map['income'] ?? 0;
    final expense = map['expense'] ?? 0;
    final balance = map['balance'] ?? 0;

    return DashboardSummary(
      currentBalance: balance,
      monthlyIncome: income,
      monthlyExpense: expense,
      remainingBudget: budget - expense,
    );
  });
});

