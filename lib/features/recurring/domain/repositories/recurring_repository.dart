import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';

abstract class RecurringRepository {
  Stream<List<RecurringRuleEntity>> watchAll();

  Future<void> addOrUpdate(RecurringRuleEntity rule);

  Future<void> setActive(String ruleId, bool isActive);

  Future<void> softDelete(String ruleId);

  Future<int> processDueRules();
}
