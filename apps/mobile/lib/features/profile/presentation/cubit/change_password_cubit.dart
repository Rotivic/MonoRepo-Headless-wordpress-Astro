import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ProfileRepository _profileRepository;

  ChangePasswordCubit(this._profileRepository)
    : super(const ChangePasswordInitial());

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      emit(const ChangePasswordLoading());

      final message = await _profileRepository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      emit(ChangePasswordSuccess(message));
    } catch (e) {
      emit(ChangePasswordError(e.toString()));
    }
  }
}
