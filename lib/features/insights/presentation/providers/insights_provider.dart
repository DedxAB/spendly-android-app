import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/insights/data/repositories/insights_repository_impl.dart';
import 'package:spendly/features/transactions/presentation/providers/transactions_provider.dart';

final expenseDistributionProvider = StreamProvider((ref) {
  return ref.watch(insightsRepositoryProvider).watchExpenseDistribution(
        ref.watch(selectedMonthProvider),
      );
});

final dailyTrendProvider = StreamProvider((ref) {
  return ref.watch(insightsRepositoryProvider).watchDailyTrend(
        ref.watch(selectedMonthProvider),
      );
});

final incomeVsExpenseProvider = StreamProvider((ref) {
  return ref.watch(insightsRepositoryProvider).watchIncomeVsExpense(
        ref.watch(selectedMonthProvider),
      );
});

