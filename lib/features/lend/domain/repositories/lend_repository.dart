import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/features/lend/domain/entities/lend_entry_entity.dart';
import 'package:spendly/features/lend/domain/entities/lend_person_entity.dart';

abstract class LendRepository {
  Stream<List<LendPersonEntity>> watchPeople();

  Stream<List<LendEntryEntity>> watchAllEntries();

  Stream<List<LendEntryEntity>> watchEntriesByPerson(String personId);

  Future<void> addPerson(String name);

  Future<void> addEntry({
    required String personId,
    required LendEntryType type,
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<void> setEntrySettled(String entryId, bool settled);
}
