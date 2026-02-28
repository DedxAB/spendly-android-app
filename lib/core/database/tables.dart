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
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();

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
  BoolColumn get isDeleted => boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Settings extends Table {
  IntColumn get id => integer()();
  RealColumn get monthlyBudget => real().named('monthly_budget').withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get themeMode => text().named('theme_mode').withDefault(const Constant('system'))();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

