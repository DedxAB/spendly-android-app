import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/transactions/domain/repositories/transactions_repository.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Future<void> add(TransactionEntity transaction) async {
    await _ref.read(appDatabaseProvider).upsertTransaction(transactionToCompanion(transaction));
  }

  @override
  Future<void> update(TransactionEntity transaction) async {
    await _ref.read(appDatabaseProvider).upsertTransaction(transactionToCompanion(transaction));
  }

  @override
  Future<void> restore(String transactionId) async {
    await _ref.read(appDatabaseProvider).restoreTransaction(transactionId);
  }

  @override
  Future<void> softDelete(String transactionId) async {
    await _ref.read(appDatabaseProvider).softDeleteTransaction(transactionId);
  }

  @override
  Stream<List<TransactionEntity>> watchByMonth(DateTime month, {String? categoryId, String? type}) {
    return _ref
        .read(appDatabaseProvider)
        .watchTransactionsByMonth(month, categoryId: categoryId, type: type)
        .map((rows) => rows.map((row) => row.toEntity()).toList(growable: false));
  }

  @override
  Stream<Map<String, double>> watchMonthlyTotals(DateTime month) {
    return _ref.read(appDatabaseProvider).watchTransactionsByMonth(month).map((rows) {
      final income = rows.where((row) => row.type == 'income').fold<double>(0, (sum, row) => sum + row.amount);
      final expense = rows.where((row) => row.type == 'expense').fold<double>(0, (sum, row) => sum + row.amount);
      return {'income': income, 'expense': expense, 'balance': income - expense};
    });
  }

  @override
  Stream<List<TransactionEntity>> watchRecent({int limit = 5}) {
    return _ref
        .read(appDatabaseProvider)
        .watchRecentTransactions(limit: limit)
        .map((rows) => rows.map((row) => row.toEntity()).toList(growable: false));
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepositoryImpl(ref);
});
