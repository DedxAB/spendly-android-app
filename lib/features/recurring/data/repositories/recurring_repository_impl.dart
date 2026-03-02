import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
import 'package:spendly/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:uuid/uuid.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  @override
  Future<void> addOrUpdate(RecurringRuleEntity rule) async {
    await _db.upsertRecurringRule(recurringRuleToCompanion(rule));
  }

  @override
  Future<void> setActive(String ruleId, bool isActive) async {
    await _db.setRecurringRuleActive(ruleId, isActive);
  }

  @override
  Future<void> softDelete(String ruleId) async {
    await _db.softDeleteRecurringRule(ruleId);
  }

  @override
  Stream<List<RecurringRuleEntity>> watchAll() {
    return _db.watchRecurringRules().map(
      (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
    );
  }

  @override
  Future<int> processDueRules() async {
    final now = DateTime.now();
    final dueRows = await _db.getDueRecurringRules(now.millisecondsSinceEpoch);
    if (dueRows.isEmpty) return 0;

    var createdCount = 0;
    await _db.transaction(() async {
      for (final row in dueRows) {
        var nextDue = DateTime.fromMillisecondsSinceEpoch(row.nextDueDate);
        var safety = 0;
        while (!nextDue.isAfter(now) && safety < 120) {
          final transactionDate = DateTime(
            nextDue.year,
            nextDue.month,
            nextDue.day,
            now.hour,
            now.minute,
          );
          await _db.upsertTransaction(
            TransactionsCompanion.insert(
              id: const Uuid().v4(),
              type: TransactionType.expense.value,
              amount: row.amount,
              categoryId: row.categoryId,
              paymentMode: PaymentModeX.fromValue(row.paymentMode).value,
              note: Value(
                row.note == null || row.note!.trim().isEmpty
                    ? 'Recurring: ${row.title}'
                    : 'Recurring: ${row.title} - ${row.note}',
              ),
              date: transactionDate.millisecondsSinceEpoch,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              isDeleted: const Value(false),
            ),
          );
          createdCount++;
          nextDue = _advanceDate(
            nextDue,
            RecurringFrequencyX.fromValue(row.frequency),
          );
          safety++;
        }

        await _db.updateRecurringRuleNextDue(
          row.id,
          nextDue.millisecondsSinceEpoch,
        );
      }
    });

    return createdCount;
  }

  DateTime _advanceDate(DateTime date, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurringFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepositoryImpl(ref);
});
