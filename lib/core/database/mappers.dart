import 'package:drift/drift.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/settings/domain/entities/settings_entity.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';

extension TransactionMapper on Transaction {
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      type: TransactionTypeX.fromValue(type),
      amount: amount,
      categoryId: categoryId,
      paymentMode: PaymentModeX.fromValue(paymentMode),
      note: note,
      date: DateTime.fromMillisecondsSinceEpoch(date),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      isDeleted: isDeleted,
    );
  }
}

extension CategoryMapper on Category {
  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      icon: icon,
      color: color,
      type: TransactionTypeX.fromValue(type),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      isDeleted: isDeleted,
    );
  }
}

extension SettingMapper on Setting {
  SettingsEntity toEntity() {
    return SettingsEntity(
      id: id,
      monthlyBudget: monthlyBudget,
      currency: currency,
      themeMode: AppThemeModeX.fromValue(themeMode),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}

TransactionsCompanion transactionToCompanion(TransactionEntity entity) {
  return TransactionsCompanion.insert(
    id: entity.id,
    type: entity.type.name,
    amount: entity.amount,
    categoryId: entity.categoryId,
    paymentMode: entity.paymentMode.name,
    note: Value(entity.note),
    date: entity.date.millisecondsSinceEpoch,
    createdAt: entity.createdAt.millisecondsSinceEpoch,
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
    isDeleted: Value(entity.isDeleted),
  );
}

CategoriesCompanion categoryToCompanion(CategoryEntity entity) {
  return CategoriesCompanion.insert(
    id: entity.id,
    name: entity.name,
    icon: entity.icon,
    color: entity.color,
    type: entity.type.name,
    createdAt: entity.createdAt.millisecondsSinceEpoch,
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
    isDeleted: Value(entity.isDeleted),
  );
}

SettingsCompanion settingsToCompanion(SettingsEntity entity) {
  return SettingsCompanion.insert(
    id: Value(entity.id),
    monthlyBudget: Value(entity.monthlyBudget),
    currency: Value(entity.currency),
    themeMode: Value(entity.themeMode.name),
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
  );
}
