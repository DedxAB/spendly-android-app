import 'package:spendly/features/insights/domain/entities/expense_slice.dart';
import 'package:spendly/features/insights/domain/entities/insight_point.dart';

abstract class InsightsRepository {
  Stream<List<ExpenseSlice>> watchExpenseDistribution(DateTime month);

  Stream<List<InsightPoint>> watchDailyTrend(DateTime month);

  Stream<Map<String, double>> watchIncomeVsExpense(DateTime month);
}
