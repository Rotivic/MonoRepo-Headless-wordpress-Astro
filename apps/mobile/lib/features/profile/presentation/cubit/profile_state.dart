import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.user);
  final UserProfile user;
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess({required this.message, this.user});
  final String message;
  final UserProfile? user;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}
