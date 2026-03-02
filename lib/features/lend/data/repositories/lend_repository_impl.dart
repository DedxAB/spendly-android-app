import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/lend/domain/entities/lend_entry_entity.dart';
import 'package:spendly/features/lend/domain/entities/lend_person_entity.dart';
import 'package:spendly/features/lend/domain/repositories/lend_repository.dart';
import 'package:uuid/uuid.dart';

class LendRepositoryImpl implements LendRepository {
  LendRepositoryImpl(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  @override
  Stream<List<LendPersonEntity>> watchPeople() {
    return _db.watchLendPeople().map(
      (rows) => rows.map((e) => e.toEntity()).toList(growable: false),
    );
  }

  @override
  Stream<List<LendEntryEntity>> watchAllEntries() {
    return _db.watchLendEntries().map(
      (rows) => rows.map((e) => e.toEntity()).toList(growable: false),
    );
  }

  @override
  Stream<List<LendEntryEntity>> watchEntriesByPerson(String personId) {
    return _db
        .watchLendEntriesByPerson(personId)
        .map((rows) => rows.map((e) => e.toEntity()).toList(growable: false));
  }

  @override
  Future<void> addPerson(String name) async {
    final now = DateTime.now();
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _db.upsertLendPerson(
      LendPeopleCompanion.insert(
        id: const Uuid().v4(),
        name: trimmed,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
        isDeleted: const Value(false),
      ),
    );
  }

  @override
  Future<void> addEntry({
    required String personId,
    required LendEntryType type,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) return;
    final now = DateTime.now();
    final normalizedNote = note?.trim().isEmpty == true ? null : note?.trim();
    await _db.upsertLendEntry(
      LendEntriesCompanion.insert(
        id: const Uuid().v4(),
        personId: personId,
        type: type.value,
        amount: amount,
        date: date.millisecondsSinceEpoch,
        note: Value(normalizedNote),
        isSettled: const Value(false),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
        isDeleted: const Value(false),
      ),
    );
  }

  @override
  Future<void> setEntrySettled(String entryId, bool settled) async {
    await _db.setLendEntrySettled(entryId, settled);
  }
}

final lendRepositoryProvider = Provider<LendRepository>((ref) {
  return LendRepositoryImpl(ref);
});
