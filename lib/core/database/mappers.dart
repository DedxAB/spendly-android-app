import 'package:drift/drift.dart';
import 'package:spendly/core/constants/app_enums.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/investments/domain/entities/investment_entity.dart';
import 'package:spendly/features/recurring/domain/entities/recurring_rule_entity.dart';
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

extension InvestmentMapper on Investment {
  InvestmentEntity toEntity() {
    return InvestmentEntity(
      id: id,
      name: name,
      type: type,
      amountInvested: amountInvested,
      currentValue: currentValue,
      investedDate: DateTime.fromMillisecondsSinceEpoch(investedDate),
      note: note,
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
      transactionHintsSeen: transactionHintsSeen,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}

extension RecurringRuleMapper on RecurringRule {
  RecurringRuleEntity toEntity() {
    return RecurringRuleEntity(
      id: id,
      title: title,
      amount: amount,
      categoryId: categoryId,
      paymentMode: PaymentModeX.fromValue(paymentMode),
      frequency: RecurringFrequencyX.fromValue(frequency),
      note: note,
      startDate: DateTime.fromMillisecondsSinceEpoch(startDate),
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(nextDueDate),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      isActive: isActive,
      isDeleted: isDeleted,
    );
  }
}

TransactionsCompanion transactionToCompanion(TransactionEntity entity) {
  return TransactionsCompanion.insert(
    id: entity.id,
    type: entity.type.value,
    amount: entity.amount,
    categoryId: entity.categoryId,
    paymentMode: entity.paymentMode.value,
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
    type: entity.type.value,
    createdAt: entity.createdAt.millisecondsSinceEpoch,
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
    isDeleted: Value(entity.isDeleted),
  );
}

InvestmentsCompanion investmentToCompanion(InvestmentEntity entity) {
  return InvestmentsCompanion.insert(
    id: entity.id,
    name: entity.name,
    type: entity.type,
    amountInvested: entity.amountInvested,
    currentValue: Value(entity.currentValue),
    investedDate: entity.investedDate.millisecondsSinceEpoch,
    note: Value(entity.note),
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
    themeMode: Value(entity.themeMode.value),
    transactionHintsSeen: Value(entity.transactionHintsSeen),
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
  );
}

RecurringRulesCompanion recurringRuleToCompanion(RecurringRuleEntity entity) {
  return RecurringRulesCompanion.insert(
    id: entity.id,
    title: entity.title,
    amount: entity.amount,
    categoryId: entity.categoryId,
    paymentMode: entity.paymentMode.value,
    frequency: entity.frequency.value,
    note: Value(entity.note),
    startDate: entity.startDate.millisecondsSinceEpoch,
    nextDueDate: entity.nextDueDate.millisecondsSinceEpoch,
    createdAt: entity.createdAt.millisecondsSinceEpoch,
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
    isActive: Value(entity.isActive),
    isDeleted: Value(entity.isDeleted),
  );
}
