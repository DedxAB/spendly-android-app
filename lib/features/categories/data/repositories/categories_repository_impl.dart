import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/categories/domain/entities/category_entity.dart';
import 'package:spendly/features/categories/domain/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Future<void> add(CategoryEntity category) async {
    await _ref
        .read(appDatabaseProvider)
        .upsertCategory(categoryToCompanion(category));
  }

  @override
  Future<void> seedDefaultsIfNeeded() async {
    await _ref.read(appDatabaseProvider).seedDefaultCategoriesIfNeeded();
  }

  @override
  Future<void> softDelete(String categoryId) async {
    await _ref.read(appDatabaseProvider).softDeleteCategory(categoryId);
  }

  @override
  Future<void> update(CategoryEntity category) async {
    await _ref
        .read(appDatabaseProvider)
        .upsertCategory(categoryToCompanion(category));
  }

  @override
  Stream<List<CategoryEntity>> watchAll() {
    return _ref
        .read(appDatabaseProvider)
        .watchCategories()
        .map(
          (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<List<CategoryEntity>> watchByType(String type) {
    return _ref
        .read(appDatabaseProvider)
        .watchCategories(type: type)
        .map(
          (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
        );
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepositoryImpl(ref);
});
