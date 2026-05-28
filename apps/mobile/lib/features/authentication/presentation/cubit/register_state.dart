import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

sealed class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  final User user;
  const RegisterSuccess(this.user);
}

class RegisterError extends RegisterState {
  final String message;
  const RegisterError(this.message);
}
