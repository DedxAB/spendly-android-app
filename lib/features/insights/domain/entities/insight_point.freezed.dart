// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$InsightPoint {
  DateTime get date => throw _privateConstructorUsedError;
  double get value => throw _privateConstructorUsedError;

  /// Create a copy of InsightPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InsightPointCopyWith<InsightPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InsightPointCopyWith<$Res> {
  factory $InsightPointCopyWith(
    InsightPoint value,
    $Res Function(InsightPoint) then,
  ) = _$InsightPointCopyWithImpl<$Res, InsightPoint>;
  @useResult
  $Res call({DateTime date, double value});
}

/// @nodoc
class _$InsightPointCopyWithImpl<$Res, $Val extends InsightPoint>
    implements $InsightPointCopyWith<$Res> {
  _$InsightPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InsightPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? value = null}) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InsightPointImplCopyWith<$Res>
    implements $InsightPointCopyWith<$Res> {
  factory _$$InsightPointImplCopyWith(
    _$InsightPointImpl value,
    $Res Function(_$InsightPointImpl) then,
  ) = __$$InsightPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, double value});
}

/// @nodoc
class __$$InsightPointImplCopyWithImpl<$Res>
    extends _$InsightPointCopyWithImpl<$Res, _$InsightPointImpl>
    implements _$$InsightPointImplCopyWith<$Res> {
  __$$InsightPointImplCopyWithImpl(
    _$InsightPointImpl _value,
    $Res Function(_$InsightPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InsightPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? value = null}) {
    return _then(
      _$InsightPointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$InsightPointImpl implements _InsightPoint {
  const _$InsightPointImpl({required this.date, required this.value});

  @override
  final DateTime date;
  @override
  final double value;

  @override
  String toString() {
    return 'InsightPoint(date: $date, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InsightPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, value);

  /// Create a copy of InsightPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InsightPointImplCopyWith<_$InsightPointImpl> get copyWith =>
      __$$InsightPointImplCopyWithImpl<_$InsightPointImpl>(this, _$identity);
}

abstract class _InsightPoint implements InsightPoint {
  const factory _InsightPoint({
    required final DateTime date,
    required final double value,
  }) = _$InsightPointImpl;

  @override
  DateTime get date;
  @override
  double get value;

  /// Create a copy of InsightPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InsightPointImplCopyWith<_$InsightPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
