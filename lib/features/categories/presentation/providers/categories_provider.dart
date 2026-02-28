import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/categories/data/repositories/categories_repository_impl.dart';

final allCategoriesProvider = StreamProvider((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});

final categoryByTypeProvider = StreamProvider.family((ref, String type) {
  return ref.watch(categoriesRepositoryProvider).watchByType(type);
});

