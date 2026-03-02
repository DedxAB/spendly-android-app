import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';

final recurringRulesProvider = StreamProvider<List<RecurringRuleEntity>>((ref) {
  return ref.watch(recurringRepositoryProvider).watchAll();
});

final recurringBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(recurringRepositoryProvider).processDueRules();
});
