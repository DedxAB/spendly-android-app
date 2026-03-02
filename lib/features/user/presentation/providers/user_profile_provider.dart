import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/user/data/repositories/user_profile_repository_impl.dart';

final userProfileProvider = StreamProvider((ref) {
  return ref.watch(userProfileRepositoryProvider).watchProfile();
});
