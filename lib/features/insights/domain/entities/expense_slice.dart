import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_slice.freezed.dart';

@freezed
class ExpenseSlice with _$ExpenseSlice {
  const factory ExpenseSlice({
    required String category,
    required String color,
    required double total,
  }) = _ExpenseSlice;
}

