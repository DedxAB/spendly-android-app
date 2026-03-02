import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/lend/domain/entities/lend_entry_entity.dart';
import 'package:spendly/features/lend/domain/entities/lend_person_entity.dart';
import 'package:spendly/features/insights/domain/entities/monthly_reflection_entity.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
import 'package:spendly/features/settings/domain/entities/settings_entity.dart';
import 'package:spendly/features/settings/domain/repositories/settings_repository.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/features/user/domain/entities/user_profile_entity.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._ref);

  final Ref _ref;

  Map<String, dynamic>? _asObjectMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  List<Map<String, dynamic>> _asObjectMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  int? _parseSchemaVersion(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _normalizeDateField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      json[key] = DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
  }

  Map<String, dynamic> _normalizeSettingsJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeUserProfileJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'createdAt');
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeCategoryJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'createdAt');
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeTransactionJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'date');
    _normalizeDateField(normalized, 'createdAt');
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeRecurringRuleJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'startDate');
    _normalizeDateField(normalized, 'nextDueDate');
    _normalizeDateField(normalized, 'createdAt');
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeLendPersonJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'createdAt');
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeLendEntryJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'date');
    _normalizeDateField(normalized, 'createdAt');
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  Map<String, dynamic> _normalizeMonthlyReflectionJson(
    Map<String, dynamic> json,
  ) {
    final normalized = Map<String, dynamic>.from(json);
    _normalizeDateField(normalized, 'updatedAt');
    return normalized;
  }

  @override
  Future<void> clearAllData() async {
    await _ref.read(appDatabaseProvider).clearAllAndReseed();
  }

  @override
  Future<String> exportJson() async {
    final db = _ref.read(appDatabaseProvider);
    final settingsRow = await db.getSettingsRow();
    final userProfileRow = await db.getUserProfileRow();
    final categories = await db.getCategories();
    final transactions = await db.watchAllActiveTransactions().first;
    final recurringRules = await db.getRecurringRules();
    final lendPeople = await db.getLendPeople();
    final lendEntries = await db.getLendEntries();
    final reflections = await db.getMonthlyReflections();

    final payload = {
      'schemaVersion': AppConstants.exportSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'settings': settingsRow?.toEntity().toJson(),
        'userProfile': userProfileRow?.toEntity().toJson(),
        'categories': categories
            .map((e) => e.toEntity().toJson())
            .toList(growable: false),
        'transactions': transactions
            .map((e) => e.toEntity().toJson())
            .toList(growable: false),
        'recurringRules': recurringRules
            .map((e) => e.toEntity().toJson())
            .toList(growable: false),
        'lendPeople': lendPeople
            .map((e) => e.toEntity().toJson())
            .toList(growable: false),
        'lendEntries': lendEntries
            .map((e) => e.toEntity().toJson())
            .toList(growable: false),
        'monthlyReflections': reflections
            .map((e) => e.toEntity().toJson())
            .toList(growable: false),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  Future<void> importJson(String payload) async {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final schemaVersion = _parseSchemaVersion(decoded['schemaVersion']);
    if (schemaVersion != AppConstants.exportSchemaVersion) {
      throw const FormatException('Unsupported schema version');
    }

    final data = _asObjectMap(decoded['data']);
    if (data == null) {
      throw const FormatException('Invalid data payload');
    }

    final settingsJson = _asObjectMap(data['settings']);
    final userProfileJson = _asObjectMap(data['userProfile']);
    final categoriesJson = _asObjectMapList(data['categories']);
    final transactionsJson = _asObjectMapList(data['transactions']);
    final recurringJson = _asObjectMapList(data['recurringRules']);
    final lendPeopleJson = _asObjectMapList(data['lendPeople']);
    final lendEntriesJson = _asObjectMapList(data['lendEntries']);
    final monthlyReflectionsJson = _asObjectMapList(data['monthlyReflections']);

    final settings = settingsJson != null
        ? SettingsEntity.fromJson(_normalizeSettingsJson(settingsJson))
        : SettingsEntity(updatedAt: DateTime.now());
    final userProfile = userProfileJson != null
        ? UserProfileEntity.fromJson(_normalizeUserProfileJson(userProfileJson))
        : UserProfileEntity(
            name: 'User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    final categoryRows = categoriesJson
        .map(
          (json) => categoryToCompanion(
            CategoryEntity.fromJson(_normalizeCategoryJson(json)),
          ),
        )
        .toList(growable: false);

    final transactionRows = transactionsJson
        .map(
          (json) => transactionToCompanion(
            TransactionEntity.fromJson(_normalizeTransactionJson(json)),
          ),
        )
        .toList(growable: false);

    final recurringRows = recurringJson
        .map(
          (json) => recurringRuleToCompanion(
            RecurringRuleEntity.fromJson(_normalizeRecurringRuleJson(json)),
          ),
        )
        .toList(growable: false);
    final lendPeopleRows = lendPeopleJson
        .map(
          (json) => lendPersonToCompanion(
            LendPersonEntity.fromJson(_normalizeLendPersonJson(json)),
          ),
        )
        .toList(growable: false);
    final lendEntryRows = lendEntriesJson
        .map(
          (json) => lendEntryToCompanion(
            LendEntryEntity.fromJson(_normalizeLendEntryJson(json)),
          ),
        )
        .toList(growable: false);
    final monthlyReflectionRows = monthlyReflectionsJson
        .map(
          (json) => monthlyReflectionToCompanion(
            MonthlyReflectionEntity.fromJson(
              _normalizeMonthlyReflectionJson(json),
            ),
          ),
        )
        .toList(growable: false);

    await _ref
        .read(appDatabaseProvider)
        .replaceAllData(
          categoryRows: categoryRows,
          transactionRows: transactionRows,
          recurringRuleRows: recurringRows,
          lendPeopleRows: lendPeopleRows,
          lendEntryRows: lendEntryRows,
          monthlyReflectionRows: monthlyReflectionRows,
          settingsRow: settingsToCompanion(settings),
          userProfileRow: userProfileToCompanion(userProfile),
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
