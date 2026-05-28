import 'package:tcg_platform_mobile/features/profile/data/dtos/dropdown_dto.dart';

abstract class EditProfileState {
  const EditProfileState();
}

class EditProfileInitial extends EditProfileState {
  const EditProfileInitial();
}

class EditProfileLoading extends EditProfileState {
  const EditProfileLoading();
}

class EditProfileDataLoaded extends EditProfileState {
  final List<DropdownItemDto> roles;
  final List<DropdownItemDto> coordinators;

  const EditProfileDataLoaded({
    required this.roles,
    required this.coordinators,
  });
}

class EditProfileSuccess extends EditProfileState {
  final String message;
  const EditProfileSuccess(this.message);
}

class EditProfileError extends EditProfileState {
  final String message;
  const EditProfileError(this.message);
}
