import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionsRepository {
  Stream<List<TransactionEntity>> watchRecent({int limit = 5});

  Stream<List<TransactionEntity>> watchByMonth(
    DateTime month, {
    String? categoryId,
    String? type,
  });

  Stream<Map<String, double>> watchMonthlyTotals(DateTime month);

  Future<void> add(TransactionEntity transaction);

  Future<void> update(TransactionEntity transaction);

  Future<void> softDelete(String transactionId);

  Future<void> restore(String transactionId);
}

