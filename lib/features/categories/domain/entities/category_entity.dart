import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendly/core/constants/app_enums.dart';

part 'category_entity.freezed.dart';
part 'category_entity.g.dart';

@freezed
class CategoryEntity with _$CategoryEntity {
  const factory CategoryEntity({
    required String id,
    required String name,
    required String icon,
    required String color,
    required TransactionType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDeleted,
  }) = _CategoryEntity;

  factory CategoryEntity.fromJson(Map<String, dynamic> json) =>
      _$CategoryEntityFromJson(json);
}
