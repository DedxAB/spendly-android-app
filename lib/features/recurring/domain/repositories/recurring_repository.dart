import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';

abstract class RecurringRepository {
  Stream<List<RecurringRuleEntity>> watchAll();

  Future<RecurringRuleEntity?> getById(String ruleId);

  Future<void> addOrUpdate(RecurringRuleEntity rule);

  Future<void> setActive(String ruleId, bool isActive);

  Future<void> updateFrequency(String ruleId, RecurringFrequency frequency);

  Future<void> softDelete(String ruleId);

  Future<void> deleteThisAndFuture({
    required String ruleId,
    required DateTime fromDate,
  });

  Future<int> processDueRules();
}
