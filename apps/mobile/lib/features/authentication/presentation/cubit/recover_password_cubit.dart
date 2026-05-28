import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/recover_password_state.dart';

class RecoverPasswordCubit extends Cubit<RecoverPasswordState> {
  RecoverPasswordCubit(this.authRepository)
    : super(const RecoverPasswordInitial());

  final AuthRepository authRepository;

  Future<void> forgotPassword(String email) async {
    emit(const RecoverPasswordLoading());
    try {
      await authRepository.forgotPassword(email);
      emit(
        const RecoverPasswordCodeSent(
          'Se ha enviado un enlace de recuperaciÃ³n a tu email',
        ),
      );
    } on NetworkException catch (e) {
      emit(RecoverPasswordError(e.message));
    } catch (_) {
      emit(const RecoverPasswordError('Error al solicitar la recuperaciÃ³n'));
    }
  }
}
