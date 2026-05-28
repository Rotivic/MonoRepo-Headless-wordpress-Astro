abstract class RecoverPasswordState {
  const RecoverPasswordState();
}

class RecoverPasswordInitial extends RecoverPasswordState {
  const RecoverPasswordInitial();
}

class RecoverPasswordLoading extends RecoverPasswordState {
  const RecoverPasswordLoading();
}

class RecoverPasswordCodeSent extends RecoverPasswordState {
  final String message;
  const RecoverPasswordCodeSent(this.message);
}

class RecoverPasswordSuccess extends RecoverPasswordState {
  final String message;
  const RecoverPasswordSuccess(this.message);
}

class RecoverPasswordError extends RecoverPasswordState {
  final String message;
  const RecoverPasswordError(this.message);
}
