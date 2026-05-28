import 'package:tcg_platform_mobile/features/profile/data/dtos/update_user_request_dto.dart';
import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';

extension UserProfileX on UserProfile {
  UpdateUserRequestDto toUpdateRequest() {
    return UpdateUserRequestDto(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }
}
