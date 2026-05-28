import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository profileRepository,
  }) : _profileRepository = profileRepository,
       super(const ProfileInitial());

  final ProfileRepository _profileRepository;

  Future<void> getUserProfile() async {
    try {
      emit(const ProfileLoading());
      final user = await _profileRepository.getUserProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> refresh() => getUserProfile();

  Future<void> updateAvatar(File avatarFile) async {
    try {
      emit(const ProfileLoading());
      await _profileRepository.updateAvatar(avatarFile);
      final user = await _profileRepository.getUserProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
