import 'package:spendly/features/insights/domain/entities/expense_slice.dart';
import 'package:spendly/features/insights/domain/entities/income_expense_bar.dart';
import 'package:spendly/features/insights/domain/entities/insight_point.dart';
import 'package:spendly/features/insights/domain/entities/monthly_reflection_entity.dart';

abstract class InsightsRepository {
  Stream<List<ExpenseSlice>> watchExpenseDistribution(
    DateTime period, {
    required bool yearly,
  });

  Stream<List<InsightPoint>> watchTrend(
    DateTime period, {
    required bool yearly,
  });

  Stream<Map<String, double>> watchIncomeVsExpense(
    DateTime period, {
    required bool yearly,
  });

  Stream<List<IncomeExpenseBar>> watchYearlyIncomeVsExpense(int year);

  Stream<Map<String, double>> watchPaymentModeBreakdown(
    DateTime period, {
    required bool yearly,
  });

  Stream<double> watchProjectedExpense(DateTime month);

  Stream<double?> watchExpenseChangePercent(
    DateTime period, {
    required bool yearly,
  });

  Stream<MonthlyReflectionEntity?> watchMonthlyReflection(String monthKey);

  Future<void> saveMonthlyReflection({
    required String monthKey,
    required String note,
  });
}
