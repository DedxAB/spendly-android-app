import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/user/domain/entities/user_profile_entity.dart';
import 'package:spendly/features/user/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Stream<UserProfileEntity> watchProfile() {
    return _ref.read(appDatabaseProvider).watchUserProfileRow().map((row) {
      if (row == null) {
        final now = DateTime.now();
        return UserProfileEntity(
          name: 'User',
          onboardingCompleted: false,
          createdAt: now,
          updatedAt: now,
        );
      }
      return row.toEntity();
    });
  }

  @override
  Future<void> updateProfile({
    required String name,
    String? imageUrl,
    String? email,
    String? phone,
    bool? onboardingCompleted,
  }) async {
    final db = _ref.read(appDatabaseProvider);
    final current = await db.getUserProfileRow();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.upsertUserProfile(
      UserProfilesCompanion.insert(
        id: const Value(1),
        name: Value(name.trim().isEmpty ? 'User' : name.trim()),
        imageUrl: Value(_normalize(imageUrl)),
        email: Value(_normalize(email)),
        phone: Value(_normalize(phone)),
        onboardingCompleted: Value(
          onboardingCompleted ?? current?.onboardingCompleted ?? false,
        ),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> completeOnboarding({String? name}) async {
    final current = await _ref.read(appDatabaseProvider).getUserProfileRow();
    await updateProfile(
      name: name ?? current?.name ?? 'User',
      imageUrl: current?.imageUrl,
      email: current?.email,
      phone: current?.phone,
      onboardingCompleted: true,
    );
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryImpl(ref);
});
