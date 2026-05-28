sealed class VerifyEmailState {
  const VerifyEmailState();
}

class VerifyEmailInitial extends VerifyEmailState {
  const VerifyEmailInitial();
}

class VerifyEmailLoading extends VerifyEmailState {
  const VerifyEmailLoading();
}

class VerifyEmailSuccess extends VerifyEmailState {
  final String message;
  const VerifyEmailSuccess(this.message);
}

class VerifyEmailVerified extends VerifyEmailState {
  const VerifyEmailVerified();
}

class VerifyEmailError extends VerifyEmailState {
  final String message;
  const VerifyEmailError(this.message);
}
