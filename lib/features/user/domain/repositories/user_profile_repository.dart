import 'package:spendly/features/user/domain/entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  Stream<UserProfileEntity> watchProfile();

  Future<void> updateProfile({
    required String name,
    String? imageUrl,
    String? email,
    String? phone,
    bool? onboardingCompleted,
  });

  Future<void> completeOnboarding({String? name});
}
