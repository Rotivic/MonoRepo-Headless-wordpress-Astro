abstract class ChangePasswordState {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends ChangePasswordState {
  final String message;
  const ChangePasswordSuccess(this.message);
}

class ChangePasswordError extends ChangePasswordState {
  final String message;
  const ChangePasswordError(this.message);
}
