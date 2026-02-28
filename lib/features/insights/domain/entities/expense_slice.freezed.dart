// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ExpenseSlice {
  String get category => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;

  /// Create a copy of ExpenseSlice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseSliceCopyWith<ExpenseSlice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseSliceCopyWith<$Res> {
  factory $ExpenseSliceCopyWith(
    ExpenseSlice value,
    $Res Function(ExpenseSlice) then,
  ) = _$ExpenseSliceCopyWithImpl<$Res, ExpenseSlice>;
  @useResult
  $Res call({String category, String color, double total});
}

/// @nodoc
class _$ExpenseSliceCopyWithImpl<$Res, $Val extends ExpenseSlice>
    implements $ExpenseSliceCopyWith<$Res> {
  _$ExpenseSliceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExpenseSlice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? color = null,
    Object? total = null,
  }) {
    return _then(
      _value.copyWith(
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExpenseSliceImplCopyWith<$Res>
    implements $ExpenseSliceCopyWith<$Res> {
  factory _$$ExpenseSliceImplCopyWith(
    _$ExpenseSliceImpl value,
    $Res Function(_$ExpenseSliceImpl) then,
  ) = __$$ExpenseSliceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String category, String color, double total});
}

/// @nodoc
class __$$ExpenseSliceImplCopyWithImpl<$Res>
    extends _$ExpenseSliceCopyWithImpl<$Res, _$ExpenseSliceImpl>
    implements _$$ExpenseSliceImplCopyWith<$Res> {
  __$$ExpenseSliceImplCopyWithImpl(
    _$ExpenseSliceImpl _value,
    $Res Function(_$ExpenseSliceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExpenseSlice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? color = null,
    Object? total = null,
  }) {
    return _then(
      _$ExpenseSliceImpl(
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$ExpenseSliceImpl implements _ExpenseSlice {
  const _$ExpenseSliceImpl({
    required this.category,
    required this.color,
    required this.total,
  });

  @override
  final String category;
  @override
  final String color;
  @override
  final double total;

  @override
  String toString() {
    return 'ExpenseSlice(category: $category, color: $color, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseSliceImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode => Object.hash(runtimeType, category, color, total);

  /// Create a copy of ExpenseSlice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseSliceImplCopyWith<_$ExpenseSliceImpl> get copyWith =>
      __$$ExpenseSliceImplCopyWithImpl<_$ExpenseSliceImpl>(this, _$identity);
}

abstract class _ExpenseSlice implements ExpenseSlice {
  const factory _ExpenseSlice({
    required final String category,
    required final String color,
    required final double total,
  }) = _$ExpenseSliceImpl;

  @override
  String get category;
  @override
  String get color;
  @override
  double get total;

  /// Create a copy of ExpenseSlice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseSliceImplCopyWith<_$ExpenseSliceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
