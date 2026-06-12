import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/verify_email_state.dart';

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit(this._authRepository, this._sessionStore)
    : super(const VerifyEmailInitial());

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  Future<void> resendEmail() async {
    final token = _sessionStore.token;
    if (token == null || token.isEmpty) {
      emit(const VerifyEmailError('No se encontro el token de sesion'));
      return;
    }

    emit(const VerifyEmailLoading());
    try {
      final message = await _authRepository.sendVerificationEmail(token);
      emit(VerifyEmailSuccess(message));
    } on NetworkException catch (e) {
      emit(VerifyEmailError(e.message));
    } catch (e) {
      emit(VerifyEmailError(e.toString()));
    }
  }

  Future<void> verifyCode(String code) async {
    final token = _sessionStore.token;
    if (token == null || token.isEmpty) {
      emit(const VerifyEmailError('No se encontro el token de sesion'));
      return;
    }

    emit(const VerifyEmailLoading());
    try {
      await _authRepository.verifyEmailCode(token: token, code: code);
      emit(const VerifyEmailVerified());
    } on NetworkException catch (e) {
      emit(VerifyEmailError(e.message));
    } catch (e) {
      emit(VerifyEmailError(e.toString()));
    }
  }

  Future<void> checkVerificationStatus() async {
    final token = _sessionStore.token;
    if (token == null || token.isEmpty) {
      emit(const VerifyEmailError('No se encontro el token de sesion'));
      return;
    }

    emit(const VerifyEmailLoading());
    try {
      final user = await _authRepository.getUserByToken(token);

      if (user.isVerified) {
        emit(const VerifyEmailVerified());
        return;
      }

      emit(const VerifyEmailError('El correo aun no ha sido verificado'));
    } on NetworkException catch (e) {
      emit(VerifyEmailError(e.message));
    } catch (e) {
      emit(VerifyEmailError(e.toString()));
    }
  }
}
