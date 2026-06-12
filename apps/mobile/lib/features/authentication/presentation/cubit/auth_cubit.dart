import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

class AuthNeedsVerification extends AuthState {
  const AuthNeedsVerification(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._sessionStore, this._authRepository)
    : super(const AuthUnknown());

  final SessionStore _sessionStore;
  final AuthRepository _authRepository;

  Future<void> initialize() async {
    await _sessionStore.initialize();

    if (!_sessionStore.hasCredentials || _sessionStore.token == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final user = await _authRepository.getUserByToken(_sessionStore.token!);
      updateAuthState(user);
    } catch (_) {
      await _sessionStore.clear();
      emit(const AuthUnauthenticated());
    }
  }

  void updateAuthState(User user) {
    if (user.isVerified) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthNeedsVerification(user));
    }
  }

  void setAuthenticated(User user) => updateAuthState(user);

  Future<void> logout() async {
    try {
      final token = _sessionStore.token;

      if (token != null && token.isNotEmpty) {
        await _authRepository.logout(token);
      }
    } catch (_) {
    } finally {
      await _sessionStore.clear();
      emit(const AuthUnauthenticated());
    }
  }
}
