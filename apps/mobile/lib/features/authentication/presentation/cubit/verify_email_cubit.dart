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
    if (token == null) {
      emit(const VerifyEmailError('No se encontrÃ³ el token de sesiÃ³n'));
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
    if (token == null) {
      emit(const VerifyEmailError('No se encontrÃ³ el token de sesiÃ³n'));
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
    final email = _sessionStore.email;
    final password = _sessionStore.password;

    if (email == null || password == null) {
      emit(const VerifyEmailError('No se encontraron credenciales guardadas'));
      return;
    }

    emit(const VerifyEmailLoading());
    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      // En el flujo de checkVerificationStatus, esperamos que el login sea directo (ya verificado)
      // o que devuelva el usuario para comprobar su estado.
      if (result.token != null && result.user != null) {
        await _sessionStore.saveCredentials(
          token: result.token!,
          email: email,
          password: password,
          userId: result.user!.id,
        );

        if (result.user!.isVerified) {
          emit(const VerifyEmailVerified());
          return;
        }
      }

      emit(const VerifyEmailError('El correo aÃºn no ha sido verificado'));
    } on NetworkException catch (e) {
      emit(VerifyEmailError(e.message));
    } catch (e) {
      emit(VerifyEmailError(e.toString()));
    }
  }
}
