import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/default_categories.dart';
import 'package:spendly/core/database/tables.dart';

part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await _resolveDatabaseFile();
    return NativeDatabase.createInBackground(file);
  });
}

Future<File> _resolveDatabaseFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'spendly.sqlite'));
  } catch (_) {
    return File(p.join(Directory.systemTemp.path, 'spendly.sqlite'));
  }
}

@DriftDatabase(
  tables: [Transactions, Categories, Investments, RecurringRules, Settings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureDefaultSettings();
      await seedDefaultCategoriesIfNeeded();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(investments);
      }
      if (from < 3) {
        await m.createTable(recurringRules);
      }
      if (from < 4) {
        await m.addColumn(settings, settings.transactionHintsSeen);
      }
    },
  );

  Future<void> _ensureDefaultSettings() async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        id: const Value(1),
        monthlyBudget: const Value(0),
        currency: const Value('INR'),
        themeMode: const Value('system'),
        transactionHintsSeen: const Value(false),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> seedDefaultCategoriesIfNeeded() async {
    final countExpr = categories.id.count();
    final countRow = await (selectOnly(
      categories,
    )..addColumns([countExpr])).getSingle();
    final count = countRow.read(countExpr) ?? 0;
    if (count > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final seed in defaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          id: seed.id,
          name: seed.name,
          icon: seed.icon,
          color: seed.color,
          type: seed.type.value,
          createdAt: now,
          updatedAt: now,
          isDeleted: const Value(false),
        ),
      );
    }
  }

  Stream<List<Transaction>> watchRecentTransactions({int limit = 5}) {
    final query = (select(transactions)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
      ..limit(limit));
    return query.watch();
  }

  Stream<List<Transaction>> watchTransactionsByMonth(
    DateTime month, {
    String? type,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    final start = dateFrom != null
        ? DateTime(
            dateFrom.year,
            dateFrom.month,
            dateFrom.day,
          ).millisecondsSinceEpoch
        : DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = dateTo != null
        ? DateTime(
            dateTo.year,
            dateTo.month,
            dateTo.day + 1,
          ).millisecondsSinceEpoch
        : DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;
    final query = select(transactions)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.date.isBiggerOrEqualValue(start))
      ..where((tbl) => tbl.date.isSmallerThanValue(end));

    if (type != null && type.isNotEmpty)
      query.where((tbl) => tbl.type.equals(type));
    if (categoryId != null && categoryId.isNotEmpty)
      query.where((tbl) => tbl.categoryId.equals(categoryId));

    query.orderBy([(tbl) => OrderingTerm.desc(tbl.date)]);
    return query.watch();
  }

  Stream<List<Transaction>> watchAllActiveTransactions() {
    final query = select(transactions)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]);
    return query.watch();
  }

  Future<void> upsertTransaction(TransactionsCompanion companion) async {
    await into(transactions).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteTransaction(String id) async {
    await (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> restoreTransaction(String id) async {
    await (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Stream<List<Category>> watchCategories({String? type}) {
    final query = select(categories)
      ..where((tbl) => tbl.isDeleted.equals(false));
    if (type != null && type.isNotEmpty)
      query.where((tbl) => tbl.type.equals(type));
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  Future<List<Category>> getCategories() {
    final query = select(categories)
      ..where((tbl) => tbl.isDeleted.equals(false));
    return query.get();
  }

  Future<void> upsertCategory(CategoriesCompanion companion) async {
    await into(categories).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteCategory(String id) async {
    await (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Stream<List<Investment>> watchInvestments() {
    final query = select(investments)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.investedDate)]);
    return query.watch();
  }

  Future<List<Investment>> getInvestments() {
    final query = select(investments)
      ..where((tbl) => tbl.isDeleted.equals(false));
    return query.get();
  }

  Future<void> upsertInvestment(InvestmentsCompanion companion) async {
    await into(investments).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteInvestment(String id) async {
    await (update(investments)..where((tbl) => tbl.id.equals(id))).write(
      InvestmentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Stream<List<RecurringRule>> watchRecurringRules() {
    final query = select(recurringRules)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.nextDueDate)]);
    return query.watch();
  }

  Future<List<RecurringRule>> getRecurringRules() {
    final query = select(recurringRules)
      ..where((tbl) => tbl.isDeleted.equals(false));
    return query.get();
  }

  Future<List<RecurringRule>> getDueRecurringRules(int nowEpoch) {
    final query = select(recurringRules)
      ..where(
        (tbl) =>
            tbl.isDeleted.equals(false) &
            tbl.isActive.equals(true) &
            tbl.nextDueDate.isSmallerOrEqualValue(nowEpoch),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.nextDueDate)]);
    return query.get();
  }

  Future<void> upsertRecurringRule(RecurringRulesCompanion companion) async {
    await into(recurringRules).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteRecurringRule(String id) async {
    await (update(recurringRules)..where((tbl) => tbl.id.equals(id))).write(
      RecurringRulesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setRecurringRuleActive(String id, bool isActive) async {
    await (update(recurringRules)..where((tbl) => tbl.id.equals(id))).write(
      RecurringRulesCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateRecurringRuleNextDue(String id, int nextDueEpoch) async {
    await (update(recurringRules)..where((tbl) => tbl.id.equals(id))).write(
      RecurringRulesCompanion(
        nextDueDate: Value(nextDueEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Stream<Setting?> watchSettingsRow() {
    final query = select(settings)..where((tbl) => tbl.id.equals(1));
    return query.watchSingleOrNull();
  }

  Future<Setting?> getSettingsRow() {
    final query = select(settings)..where((tbl) => tbl.id.equals(1));
    return query.getSingleOrNull();
  }

  Future<void> upsertSettings(SettingsCompanion companion) async {
    await into(settings).insertOnConflictUpdate(companion);
  }

  Future<void> replaceAllData({
    required List<CategoriesCompanion> categoryRows,
    required List<TransactionsCompanion> transactionRows,
    required List<InvestmentsCompanion> investmentRows,
    required List<RecurringRulesCompanion> recurringRuleRows,
    required SettingsCompanion settingsRow,
  }) async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(categories).go();
      await delete(investments).go();
      await delete(recurringRules).go();
      await delete(settings).go();
      if (categoryRows.isNotEmpty)
        await batch((b) => b.insertAll(categories, categoryRows));
      if (transactionRows.isNotEmpty)
        await batch((b) => b.insertAll(transactions, transactionRows));
      if (investmentRows.isNotEmpty)
        await batch((b) => b.insertAll(investments, investmentRows));
      if (recurringRuleRows.isNotEmpty)
        await batch((b) => b.insertAll(recurringRules, recurringRuleRows));
      await into(settings).insertOnConflictUpdate(settingsRow);
    });
  }

  Future<void> clearAllAndReseed() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(categories).go();
      await delete(investments).go();
      await delete(recurringRules).go();
      await delete(settings).go();
      await _ensureDefaultSettings();
      await seedDefaultCategoriesIfNeeded();
    });
  }
}
