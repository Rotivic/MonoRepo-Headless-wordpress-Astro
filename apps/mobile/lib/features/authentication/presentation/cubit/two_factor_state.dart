import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

sealed class TwoFactorState {
  const TwoFactorState();
}

class TwoFactorInitial extends TwoFactorState {
  const TwoFactorInitial();
}

class TwoFactorLoading extends TwoFactorState {
  const TwoFactorLoading();
}

class TwoFactorSuccess extends TwoFactorState {
  final User user;
  const TwoFactorSuccess(this.user);
}

class TwoFactorError extends TwoFactorState {
  final String message;
  const TwoFactorError(this.message);
}
