import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/features/lend/data/repositories/lend_repository_impl.dart';
import 'package:spendly/features/lend/domain/entities/lend_entry_entity.dart';
import 'package:spendly/features/lend/domain/entities/lend_person_entity.dart';

final lendPeopleProvider = StreamProvider<List<LendPersonEntity>>((ref) {
  return ref.watch(lendRepositoryProvider).watchPeople();
});

final lendEntriesProvider = StreamProvider<List<LendEntryEntity>>((ref) {
  return ref.watch(lendRepositoryProvider).watchAllEntries();
});

final lendEntriesByPersonProvider =
    StreamProvider.family<List<LendEntryEntity>, String>((ref, personId) {
      return ref.watch(lendRepositoryProvider).watchEntriesByPerson(personId);
    });

class LendPersonBalance {
  const LendPersonBalance({
    required this.person,
    required this.netBalance,
    required this.activeEntryCount,
  });

  final LendPersonEntity person;
  final double netBalance;
  final int activeEntryCount;
}

class LendOverview {
  const LendOverview({
    required this.totalToReceive,
    required this.totalToPay,
    required this.peopleBalances,
  });

  final double totalToReceive;
  final double totalToPay;
  final List<LendPersonBalance> peopleBalances;
}

final lendOverviewProvider = Provider<AsyncValue<LendOverview>>((ref) {
  final peopleAsync = ref.watch(lendPeopleProvider);
  final entriesAsync = ref.watch(lendEntriesProvider);

  if (peopleAsync.isLoading || entriesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (peopleAsync.hasError) {
    return AsyncValue.error(peopleAsync.error!, peopleAsync.stackTrace!);
  }
  if (entriesAsync.hasError) {
    return AsyncValue.error(entriesAsync.error!, entriesAsync.stackTrace!);
  }

  final people = peopleAsync.valueOrNull ?? const <LendPersonEntity>[];
  final entries = entriesAsync.valueOrNull ?? const <LendEntryEntity>[];

  final balances =
      people
          .map((person) {
            final personEntries = entries.where((e) => e.personId == person.id);
            final active = personEntries.where(
              (e) => !e.isSettled && !e.isDeleted,
            );
            final net = active.fold<double>(0, (sum, e) {
              if (e.type == LendEntryType.lent) return sum + e.amount;
              return sum - e.amount;
            });

            return LendPersonBalance(
              person: person,
              netBalance: net,
              activeEntryCount: active.length,
            );
          })
          .toList(growable: false)
        ..sort((a, b) => b.netBalance.abs().compareTo(a.netBalance.abs()));

  final totalToReceive = balances
      .where((e) => e.netBalance > 0)
      .fold<double>(0, (sum, e) => sum + e.netBalance);
  final totalToPay = balances
      .where((e) => e.netBalance < 0)
      .fold<double>(0, (sum, e) => sum + e.netBalance.abs());

  return AsyncValue.data(
    LendOverview(
      totalToReceive: totalToReceive,
      totalToPay: totalToPay,
      peopleBalances: balances,
    ),
  );
});
