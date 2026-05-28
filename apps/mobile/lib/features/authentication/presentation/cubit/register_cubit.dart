import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._authRepository, this._sessionStore)
    : super(const RegisterInitial());

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(const RegisterLoading());

    try {
      final result = await _authRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (result.token != null && result.user != null) {
        await _sessionStore.saveCredentials(
          token: result.token!,
          email: email,
          password: password,
          userId: result.user!.id,
        );

        emit(RegisterSuccess(result.user!));
      } else {
        emit(const RegisterError('Error inesperado durante el registro'));
      }
    } on NetworkException catch (e) {
      emit(RegisterError(e.message));
    } catch (e) {
      emit(RegisterError(e.toString()));
    }
  }
}
