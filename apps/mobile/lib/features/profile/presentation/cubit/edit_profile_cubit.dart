import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  final ProfileRepository _profileRepository;

  EditProfileCubit(this._profileRepository) : super(const EditProfileInitial());

  Future<void> updateUser(
    UserProfile user, {
    File? avatarFile,
  }) async {
    try {
      emit(const EditProfileLoading());

      if (avatarFile != null) {
        await _profileRepository.updateAvatar(avatarFile);
      }

      final message = await _profileRepository.updateUserProfile(user);
      emit(EditProfileSuccess(message));
    } catch (e) {
      emit(EditProfileError(e.toString()));
    }
  }
}
