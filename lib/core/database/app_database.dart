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
    // Fallback for test environments where plugins are unavailable.
    return File(p.join(Directory.systemTemp.path, 'spendly.sqlite'));
  }
}

@DriftDatabase(tables: [Transactions, Categories, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureDefaultSettings();
          await seedDefaultCategoriesIfNeeded();
        },
      );

  Future<void> _ensureDefaultSettings() async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        id: const Value(1),
        monthlyBudget: const Value(0),
        currency: const Value('INR'),
        themeMode: const Value('system'),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> seedDefaultCategoriesIfNeeded() async {
    final countExpr = categories.id.count();
    final countRow = await (selectOnly(categories)..addColumns([countExpr])).getSingle();
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

  Stream<List<Transaction>> watchTransactionsByMonth(DateTime month, {String? type, String? categoryId}) {
    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;
    final query = select(transactions)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.date.isBiggerOrEqualValue(start))
      ..where((tbl) => tbl.date.isSmallerThanValue(end));

    if (type != null && type.isNotEmpty) query.where((tbl) => tbl.type.equals(type));
    if (categoryId != null && categoryId.isNotEmpty) query.where((tbl) => tbl.categoryId.equals(categoryId));

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
      TransactionsCompanion(isDeleted: const Value(true), updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future<void> restoreTransaction(String id) async {
    await (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
      TransactionsCompanion(isDeleted: const Value(false), updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Stream<List<Category>> watchCategories({String? type}) {
    final query = select(categories)..where((tbl) => tbl.isDeleted.equals(false));
    if (type != null && type.isNotEmpty) query.where((tbl) => tbl.type.equals(type));
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  Future<List<Category>> getCategories() {
    final query = select(categories)..where((tbl) => tbl.isDeleted.equals(false));
    return query.get();
  }

  Future<void> upsertCategory(CategoriesCompanion companion) async {
    await into(categories).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteCategory(String id) async {
    await (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(isDeleted: const Value(true), updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
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
    required SettingsCompanion settingsRow,
  }) async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(categories).go();
      await delete(settings).go();
      if (categoryRows.isNotEmpty) await batch((b) => b.insertAll(categories, categoryRows));
      if (transactionRows.isNotEmpty) await batch((b) => b.insertAll(transactions, transactionRows));
      await into(settings).insertOnConflictUpdate(settingsRow);
    });
  }

  Future<void> clearAllAndReseed() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(categories).go();
      await delete(settings).go();
      await _ensureDefaultSettings();
      await seedDefaultCategoriesIfNeeded();
    });
  }
}
