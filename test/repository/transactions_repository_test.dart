import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('soft delete and restore transaction', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.upsertTransaction(
      TransactionsCompanion.insert(
        id: 'tx-1',
        type: 'expense',
        amount: 100,
        categoryId: 'cat_food',
        paymentMode: 'upi',
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    var active = await db.watchAllActiveTransactions().first;
    expect(active.length, 1);

    await db.softDeleteTransaction('tx-1');
    active = await db.watchAllActiveTransactions().first;
    expect(active, isEmpty);

    await db.restoreTransaction('tx-1');
    active = await db.watchAllActiveTransactions().first;
    expect(active.length, 1);
  });
}
