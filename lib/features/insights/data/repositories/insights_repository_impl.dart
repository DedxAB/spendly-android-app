import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/features/insights/domain/entities/expense_slice.dart';
import 'package:spendly/features/insights/domain/entities/insight_point.dart';
import 'package:spendly/features/insights/domain/repositories/insights_repository.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  InsightsRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Stream<List<InsightPoint>> watchDailyTrend(DateTime month) {
    return _ref.read(appDatabaseProvider).watchTransactionsByMonth(month, type: 'expense').map((rows) {
      final totals = <DateTime, double>{};
      for (final row in rows) {
        final date = DateTime.fromMillisecondsSinceEpoch(row.date);
        final day = DateTime(date.year, date.month, date.day);
        totals[day] = (totals[day] ?? 0) + row.amount;
      }
      final points = totals.entries
          .map((e) => InsightPoint(date: e.key, value: e.value))
          .toList(growable: false)
        ..sort((a, b) => a.date.compareTo(b.date));
      return points;
    });
  }

  @override
  Stream<List<ExpenseSlice>> watchExpenseDistribution(DateTime month) {
    final db = _ref.read(appDatabaseProvider);
    return db.watchTransactionsByMonth(month, type: 'expense').asyncMap((rows) async {
      final categories = await db.getCategories();
      final nameById = {
        for (final category in categories) category.id: (category.name, category.color),
      };
      final totals = <String, double>{};
      for (final row in rows) {
        final name = nameById[row.categoryId]?.$1 ?? 'Other';
        totals[name] = (totals[name] ?? 0) + row.amount;
      }
      return totals.entries
          .map((entry) {
            final color = nameById.entries
                    .firstWhere(
                      (element) => element.value.$1 == entry.key,
                      orElse: () => const MapEntry('', ('Other', '#94A3B8')),
                    )
                    .value
                    .$2;
            return ExpenseSlice(category: entry.key, color: color, total: entry.value);
          })
          .toList(growable: false);
    });
  }

  @override
  Stream<Map<String, double>> watchIncomeVsExpense(DateTime month) {
    return _ref.read(appDatabaseProvider).watchTransactionsByMonth(month).map((rows) {
      final income = rows
          .where((row) => row.type == 'income')
          .fold<double>(0, (sum, row) => sum + row.amount);
      final expense = rows
          .where((row) => row.type == 'expense')
          .fold<double>(0, (sum, row) => sum + row.amount);
      return {'income': income, 'expense': expense};
    });
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepositoryImpl(ref);
});

