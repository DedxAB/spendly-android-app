import 'package:spendly/features/settings/domain/entities/settings_entity.dart';

abstract class SettingsRepository {
  Stream<SettingsEntity> watchSettings();

  Future<void> setBudget(double budget);

  Future<void> setThemeMode(String themeMode);

  Future<void> markTransactionHintsSeen();

  Future<String> exportJson();

  Future<void> importJson(String payload);

  Future<void> clearAllData();
}
