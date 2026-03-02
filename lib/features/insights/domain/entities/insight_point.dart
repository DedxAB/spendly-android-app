import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_point.freezed.dart';

@freezed
class InsightPoint with _$InsightPoint {
  const factory InsightPoint({required DateTime date, required double value}) =
      _InsightPoint;
}
