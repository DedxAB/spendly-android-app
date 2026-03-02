import 'package:spendly/features/categories/domain/entities/category_entity.dart';

abstract class CategoriesRepository {
  Stream<List<CategoryEntity>> watchByType(String type);
  Stream<List<CategoryEntity>> watchAll();

  Future<void> add(CategoryEntity category);

  Future<void> update(CategoryEntity category);

  Future<void> softDelete(String categoryId);

  Future<void> seedDefaultsIfNeeded();
}
