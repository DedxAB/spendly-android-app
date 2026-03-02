import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/investments/data/repositories/investments_repository_impl.dart';

final investmentsProvider = StreamProvider((ref) {
  return ref.watch(investmentsRepositoryProvider).watchAll();
});
