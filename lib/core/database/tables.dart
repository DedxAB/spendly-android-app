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

class Investments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get amountInvested => real().named('amount_invested')();
  RealColumn get currentValue => real().named('current_value').nullable()();
  IntColumn get investedDate => integer().named('invested_date')();
  TextColumn get note => text().nullable()();
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
