import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User user;
  LoginSuccess(this.user);
}

class LoginTwoFactorRequired extends LoginState {
  final String challengeToken;
  LoginTwoFactorRequired(this.challengeToken);
}

class LoginError extends LoginState {
  final String message;
  LoginError(this.message);
}
