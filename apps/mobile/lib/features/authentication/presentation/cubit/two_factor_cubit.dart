import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/two_factor_state.dart';

class TwoFactorCubit extends Cubit<TwoFactorState> {
  TwoFactorCubit(this._authRepository, this._sessionStore)
    : super(const TwoFactorInitial());

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  Future<void> verify({
    required String challengeToken,
    required String email,
    required String password,
    String? code,
    String? recoveryCode,
  }) async {
    emit(const TwoFactorLoading());

    try {
      final result = await _authRepository.verifyTwoFactor(
        challengeToken: challengeToken,
        code: code,
        recoveryCode: recoveryCode,
      );

      await _sessionStore.saveCredentials(
        token: result.token!,
        email: email,
        password: password,
        userId: result.user!.id,
      );

      emit(TwoFactorSuccess(result.user!));
    } on NetworkException catch (e) {
      emit(TwoFactorError(e.message));
    } catch (e) {
      emit(TwoFactorError(e.toString()));
    }
  }
}
