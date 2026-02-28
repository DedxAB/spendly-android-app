import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final transactionTypeFilterProvider = StateProvider<String?>((ref) => null);
final transactionCategoryFilterProvider = StateProvider<String?>((ref) => null);

final monthlyTransactionsProvider = StreamProvider((ref) {
  final month = ref.watch(selectedMonthProvider);
  final type = ref.watch(transactionTypeFilterProvider);
  final categoryId = ref.watch(transactionCategoryFilterProvider);
  return ref
      .watch(transactionsRepositoryProvider)
      .watchByMonth(month, type: type, categoryId: categoryId);
});

final recentTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchRecent(limit: 5);
});

final monthlyTotalsProvider = StreamProvider((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionsRepositoryProvider).watchMonthlyTotals(month);
});

class TransactionActions {
  TransactionActions(this._ref);

  final Ref _ref;

  Future<void> save(TransactionEntity transaction) async {
    await _ref.read(transactionsRepositoryProvider).add(transaction);
  }

  Future<void> update(TransactionEntity transaction) async {
    await _ref.read(transactionsRepositoryProvider).update(transaction);
  }

  Future<void> softDelete(String id) async {
    await _ref.read(transactionsRepositoryProvider).softDelete(id);
  }

  Future<void> restore(String id) async {
    await _ref.read(transactionsRepositoryProvider).restore(id);
  }
}

final transactionActionsProvider = Provider(TransactionActions.new);
