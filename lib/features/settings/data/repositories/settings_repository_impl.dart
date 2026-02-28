import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/investments/domain/entities/investment_entity.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
import 'package:spendly/features/settings/domain/entities/settings_entity.dart';
import 'package:spendly/features/settings/domain/repositories/settings_repository.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Future<void> clearAllData() async {
    await _ref.read(appDatabaseProvider).clearAllAndReseed();
  }

  @override
  Future<String> exportJson() async {
    final db = _ref.read(appDatabaseProvider);
    final settingsRow = await db.getSettingsRow();
    final categories = await db.getCategories();
    final transactions = await db.watchAllActiveTransactions().first;
    final investments = await db.getInvestments();
    final recurringRules = await db.getRecurringRules();

    final payload = {
      'schemaVersion': AppConstants.exportSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'settings': settingsRow?.toJson(),
        'categories': categories.map((e) => e.toJson()).toList(growable: false),
        'transactions': transactions
            .map((e) => e.toJson())
            .toList(growable: false),
        'investments': investments
            .map((e) => e.toJson())
            .toList(growable: false),
        'recurringRules': recurringRules
            .map((e) => e.toJson())
            .toList(growable: false),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  Future<void> importJson(String payload) async {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final schemaVersion = decoded['schemaVersion'] as int?;
    if (schemaVersion != AppConstants.exportSchemaVersion) {
      throw const FormatException('Unsupported schema version');
    }

    final data = decoded['data'] as Map<String, dynamic>;
    final settingsJson = (data['settings'] as Map?)?.cast<String, dynamic>();
    final categoriesJson =
        (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final transactionsJson =
        (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final investmentsJson =
        (data['investments'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final recurringJson =
        (data['recurringRules'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];

    final settings = settingsJson != null
        ? SettingsEntity.fromJson(settingsJson)
        : SettingsEntity(updatedAt: DateTime.now());

    final categoryRows = categoriesJson
        .map((json) => categoryToCompanion(CategoryEntity.fromJson(json)))
        .toList(growable: false);

    final transactionRows = transactionsJson
        .map((json) => transactionToCompanion(TransactionEntity.fromJson(json)))
        .toList(growable: false);

    final investmentRows = investmentsJson
        .map((json) => investmentToCompanion(InvestmentEntity.fromJson(json)))
        .toList(growable: false);

    final recurringRows = recurringJson
        .map(
          (json) =>
              recurringRuleToCompanion(RecurringRuleEntity.fromJson(json)),
        )
        .toList(growable: false);

    await _ref
        .read(appDatabaseProvider)
        .replaceAllData(
          categoryRows: categoryRows,
          transactionRows: transactionRows,
          investmentRows: investmentRows,
          recurringRuleRows: recurringRows,
          settingsRow: settingsToCompanion(settings),
        );
  }

  @override
  Future<void> setBudget(double budget) async {
    final db = _ref.read(appDatabaseProvider);
    final current = await db.getSettingsRow();
    await db.upsertSettings(
      SettingsCompanion.insert(
        id: const Value(1),
        monthlyBudget: Value(budget),
        currency: Value(current?.currency ?? 'INR'),
        themeMode: Value(current?.themeMode ?? AppThemeMode.system.value),
        transactionHintsSeen: Value(current?.transactionHintsSeen ?? false),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    final db = _ref.read(appDatabaseProvider);
    final current = await db.getSettingsRow();
    await db.upsertSettings(
      SettingsCompanion.insert(
        id: const Value(1),
        monthlyBudget: Value(current?.monthlyBudget ?? 0),
        currency: Value(current?.currency ?? 'INR'),
        themeMode: Value(themeMode),
        transactionHintsSeen: Value(current?.transactionHintsSeen ?? false),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> markTransactionHintsSeen() async {
    final db = _ref.read(appDatabaseProvider);
    final current = await db.getSettingsRow();
    await db.upsertSettings(
      SettingsCompanion.insert(
        id: const Value(1),
        monthlyBudget: Value(current?.monthlyBudget ?? 0),
        currency: Value(current?.currency ?? 'INR'),
        themeMode: Value(current?.themeMode ?? AppThemeMode.system.value),
        transactionHintsSeen: const Value(true),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Stream<SettingsEntity> watchSettings() {
    return _ref.read(appDatabaseProvider).watchSettingsRow().map((row) {
      if (row == null) {
        return SettingsEntity(
          updatedAt: DateTime.now(),
          themeMode: AppThemeMode.system,
        );
      }
      return row.toEntity();
    });
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref);
});
