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
  tables: [
    Transactions,
    Categories,
    RecurringRules,
    Settings,
    UserProfiles,
    LendPeople,
    LendEntries,
    MonthlyReflections,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureDefaultSettings();
      await _ensureDefaultUserProfile();
      await seedDefaultCategoriesIfNeeded();
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(recurringRules);
      }
      if (from < 4) {
        await m.addColumn(settings, settings.transactionHintsSeen);
      }
      if (from < 5) {
        await m.createTable(userProfiles);
        await _ensureDefaultUserProfile();
      }
      if (from < 6) {
        await m.addColumn(userProfiles, userProfiles.onboardingCompleted);
      }
      if (from < 7) {
        await customStatement('DROP TABLE IF EXISTS investments;');
      }
      if (from < 8) {
        await m.createTable(lendPeople);
        await m.createTable(lendEntries);
      }
      if (from < 9) {
        await m.createTable(monthlyReflections);
      }
      if (from < 10) {
        await m.addColumn(transactions, transactions.recurringRuleId);
        await m.addColumn(transactions, transactions.isRecurringInstance);
        await m.addColumn(recurringRules, recurringRules.type);
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

  Future<void> _ensureDefaultUserProfile() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(userProfiles).insertOnConflictUpdate(
      UserProfilesCompanion.insert(
        id: const Value(1),
        name: const Value('User'),
        imageUrl: const Value(null),
        email: const Value(null),
        phone: const Value(null),
        onboardingCompleted: const Value(false),
        createdAt: now,
        updatedAt: now,
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

  Future<void> softDeleteTransactionsByRecurringRuleFromDate(
    String ruleId,
    int fromDateEpoch,
  ) async {
    await (update(transactions)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..where((tbl) => tbl.recurringRuleId.equals(ruleId))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(fromDateEpoch)))
        .write(
          TransactionsCompanion(
            isDeleted: const Value(true),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<bool> hasActiveRecurringOccurrenceOnDate({
    required String ruleId,
    required int dayStartEpoch,
    required int dayEndExclusiveEpoch,
  }) async {
    final countExpr = transactions.id.count();
    final query = selectOnly(transactions)
      ..addColumns([countExpr])
      ..where(transactions.isDeleted.equals(false))
      ..where(transactions.recurringRuleId.equals(ruleId))
      ..where(transactions.date.isBiggerOrEqualValue(dayStartEpoch))
      ..where(transactions.date.isSmallerThanValue(dayEndExclusiveEpoch));
    final row = await query.getSingle();
    final count = row.read(countExpr) ?? 0;
    return count > 0;
  }

  Future<RecurringRule?> getRecurringRuleById(String ruleId) {
    final query = select(recurringRules)..where((tbl) => tbl.id.equals(ruleId));
    return query.getSingleOrNull();
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

  Stream<UserProfile?> watchUserProfileRow() {
    final query = select(userProfiles)..where((tbl) => tbl.id.equals(1));
    return query.watchSingleOrNull();
  }

  Future<UserProfile?> getUserProfileRow() {
    final query = select(userProfiles)..where((tbl) => tbl.id.equals(1));
    return query.getSingleOrNull();
  }

  Future<void> upsertUserProfile(UserProfilesCompanion companion) async {
    await into(userProfiles).insertOnConflictUpdate(companion);
  }

  Stream<List<LendPeopleData>> watchLendPeople() {
    final query = select(lendPeople)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  Future<List<LendPeopleData>> getLendPeople() {
    final query = select(lendPeople)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.get();
  }

  Future<void> upsertLendPerson(LendPeopleCompanion companion) async {
    await into(lendPeople).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteLendPerson(String personId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(lendPeople)..where((tbl) => tbl.id.equals(personId))).write(
      LendPeopleCompanion(isDeleted: const Value(true), updatedAt: Value(now)),
    );
    await (update(
      lendEntries,
    )..where((tbl) => tbl.personId.equals(personId))).write(
      LendEntriesCompanion(isDeleted: const Value(true), updatedAt: Value(now)),
    );
  }

  Stream<List<LendEntry>> watchLendEntries() {
    final query = select(lendEntries)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]);
    return query.watch();
  }

  Stream<List<LendEntry>> watchLendEntriesByPerson(String personId) {
    final query = select(lendEntries)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.personId.equals(personId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]);
    return query.watch();
  }

  Future<List<LendEntry>> getLendEntries() {
    final query = select(lendEntries)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]);
    return query.get();
  }

  Future<void> upsertLendEntry(LendEntriesCompanion companion) async {
    await into(lendEntries).insertOnConflictUpdate(companion);
  }

  Future<void> setLendEntrySettled(String entryId, bool isSettled) async {
    await (update(lendEntries)..where((tbl) => tbl.id.equals(entryId))).write(
      LendEntriesCompanion(
        isSettled: Value(isSettled),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Stream<MonthlyReflection?> watchMonthlyReflection(String monthKey) {
    final query = select(monthlyReflections)
      ..where((tbl) => tbl.monthKey.equals(monthKey));
    return query.watchSingleOrNull();
  }

  Future<List<MonthlyReflection>> getMonthlyReflections() {
    return select(monthlyReflections).get();
  }

  Future<void> upsertMonthlyReflection(
    MonthlyReflectionsCompanion companion,
  ) async {
    await into(monthlyReflections).insertOnConflictUpdate(companion);
  }

  Future<void> replaceAllData({
    required List<CategoriesCompanion> categoryRows,
    required List<TransactionsCompanion> transactionRows,
    required List<RecurringRulesCompanion> recurringRuleRows,
    required List<LendPeopleCompanion> lendPeopleRows,
    required List<LendEntriesCompanion> lendEntryRows,
    required List<MonthlyReflectionsCompanion> monthlyReflectionRows,
    required SettingsCompanion settingsRow,
    required UserProfilesCompanion userProfileRow,
  }) async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(categories).go();
      await delete(recurringRules).go();
      await delete(lendEntries).go();
      await delete(lendPeople).go();
      await delete(monthlyReflections).go();
      await delete(settings).go();
      await delete(userProfiles).go();
      if (categoryRows.isNotEmpty)
        await batch((b) => b.insertAll(categories, categoryRows));
      if (transactionRows.isNotEmpty)
        await batch((b) => b.insertAll(transactions, transactionRows));
      if (recurringRuleRows.isNotEmpty)
        await batch((b) => b.insertAll(recurringRules, recurringRuleRows));
      if (lendPeopleRows.isNotEmpty)
        await batch((b) => b.insertAll(lendPeople, lendPeopleRows));
      if (lendEntryRows.isNotEmpty)
        await batch((b) => b.insertAll(lendEntries, lendEntryRows));
      if (monthlyReflectionRows.isNotEmpty)
        await batch(
          (b) => b.insertAll(monthlyReflections, monthlyReflectionRows),
        );
      await into(settings).insertOnConflictUpdate(settingsRow);
      await into(userProfiles).insertOnConflictUpdate(userProfileRow);
    });
  }

  Future<void> clearAllAndReseed() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(categories).go();
      await delete(recurringRules).go();
      await delete(lendEntries).go();
      await delete(lendPeople).go();
      await delete(monthlyReflections).go();
      await delete(settings).go();
      await delete(userProfiles).go();
      await _ensureDefaultSettings();
      await _ensureDefaultUserProfile();
      await seedDefaultCategoriesIfNeeded();
    });
  }
}
