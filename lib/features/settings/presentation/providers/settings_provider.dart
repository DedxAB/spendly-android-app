import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/settings/data/repositories/settings_repository_impl.dart';

final settingsStreamProvider = StreamProvider((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});
