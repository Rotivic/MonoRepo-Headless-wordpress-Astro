import 'package:tcg_platform_mobile/features/profile/data/dtos/user_profile_dto.dart';
import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';

extension UserProfileDtoX on UserProfileDto {
  UserProfile toDomain() {
    return UserProfile(
      id: id,
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      email: email ?? '',
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      twoFactorEnabled: twoFactorEnabled,
      isVerified: isVerified,
      isEnabled: isEnabled,
      roles:
          roles
              ?.map((role) => role.id)
              .whereType<String>()
              .where((role) => role.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}
