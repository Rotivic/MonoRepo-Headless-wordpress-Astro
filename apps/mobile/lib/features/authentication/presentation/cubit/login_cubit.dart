import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this.authRepository, this.sessionStore) : super(LoginInitial());

  final AuthRepository authRepository;
  final SessionStore sessionStore;

  Future<void> login(String email, String password) async {
    emit(LoginLoading());

    try {
      final result = await authRepository.login(
        email: email,
        password: password,
      );

      if (result.twoFactorRequired) {
        emit(LoginTwoFactorRequired(result.challengeToken!));
        return;
      }

      await sessionStore.saveCredentials(
        token: result.token!,
        email: email,
        password: password,
        userId: result.user!.id,
      );

      emit(LoginSuccess(result.user!));
    } on NetworkException catch (e) {
      emit(LoginError(e.message));
    } catch (_) {
      emit(LoginError('Login fallido'));
    }
  }
}
