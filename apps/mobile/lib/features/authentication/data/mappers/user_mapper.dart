import 'package:tcg_platform_mobile/features/authentication/data/dtos/user_dto.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

extension UserDtoX on UserDto {
  User toDomain() => User(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    enabled: enabled ?? false,
    isVerified: isVerified ?? false,
  );
}
