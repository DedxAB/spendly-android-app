import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get paymentMode => text().named('payment_mode')();
  TextColumn get note => text().nullable()();
  IntColumn get date => integer()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  TextColumn get recurringRuleId =>
      text().named('recurring_rule_id').nullable()();
  BoolColumn get isRecurringInstance => boolean()
      .named('is_recurring_instance')
      .withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [];
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get type => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  RealColumn get amount => real()();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get paymentMode => text().named('payment_mode')();
  TextColumn get frequency => text()();
  TextColumn get note => text().nullable()();
  IntColumn get startDate => integer().named('start_date')();
  IntColumn get nextDueDate => integer().named('next_due_date')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Settings extends Table {
  IntColumn get id => integer()();
  RealColumn get monthlyBudget =>
      real().named('monthly_budget').withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get themeMode =>
      text().named('theme_mode').withDefault(const Constant('system'))();
  BoolColumn get transactionHintsSeen => boolean()
      .named('transaction_hints_seen')
      .withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UserProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withDefault(const Constant('User'))();
  TextColumn get imageUrl => text().named('image_url').nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  BoolColumn get onboardingCompleted => boolean()
      .named('onboarding_completed')
      .withDefault(const Constant(false))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LendPeople extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LendEntries extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().named('person_id')();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  BoolColumn get isSettled =>
      boolean().named('is_settled').withDefault(const Constant(false))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MonthlyReflections extends Table {
  TextColumn get monthKey => text().named('month_key')();
  TextColumn get note => text()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {monthKey};
}
