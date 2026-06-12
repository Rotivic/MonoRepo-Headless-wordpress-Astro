import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_state.dart';

import '../../../../helpers/mocks.dart';

class MockSessionStore extends Mock implements SessionStore {}

void main() {
  late MockAuthRepository repo;
  late MockSessionStore sessionStore;

  setUpAll(() {
    registerFallbackValue(FakeUser());
    registerFallbackValue(FakeLoginResult());
  });

  setUp(() {
    repo = MockAuthRepository();
    sessionStore = MockSessionStore();
  });

  blocTest<LoginCubit, LoginState>(
    'emite [LoginLoading, LoginSuccess] cuando login va bien y guarda credenciales',
    build: () {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => makeLoginResult(token: 'abc'));

      when(
        () => sessionStore.saveCredentials(
          token: any(named: 'token'),
          email: any(named: 'email'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});

      return LoginCubit(repo, sessionStore);
    },
    act: (cubit) => cubit.login('a@a.com', '123456'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginSuccess>().having((s) => s.user.id, 'id', 1),
    ],
    verify: (_) {
      verify(() => repo.login(email: 'a@a.com', password: '123456')).called(1);
      verify(
        () => sessionStore.saveCredentials(
          token: 'abc',
          email: 'a@a.com',
          userId: 1,
        ),
      ).called(1);
    },
  );

  blocTest<LoginCubit, LoginState>(
    'emite [LoginLoading, LoginError] cuando el repo lanza NetworkException',
    build: () {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(NetworkException('Bad credentials'));

      return LoginCubit(repo, sessionStore);
    },
    act: (cubit) => cubit.login('a@a.com', 'wrong'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginError>().having((s) => s.message, 'message', 'Bad credentials'),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'emite [LoginLoading, LoginError] con mensaje genÃ©rico en error inesperado',
    build: () {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('boom'));

      return LoginCubit(repo, sessionStore);
    },
    act: (cubit) => cubit.login('a@a.com', '123456'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginError>().having((s) => s.message, 'message', 'Login fallido'),
    ],
  );
}
