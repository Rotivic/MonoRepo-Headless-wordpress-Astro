import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/login_page.dart';
import 'package:tcg_platform_mobile/l10n/gen/app_localizations.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  AppLocalizations l10nFor(WidgetTester tester) {
    final context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context);
    expect(l10n, isNotNull);
    return l10n;
  }

  testWidgets('renderiza la pantalla de login (con l10n)', (tester) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => makeLoginResult());

    await pumpLoginApp(tester, authRepository: repo);

    final l10n = l10nFor(tester);

    expect(find.text(l10n.loginHeaderTitle.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.loginHeaderSubtitle), findsOneWidget);

    expect(find.byKey(LoginPage.emailKey), findsOneWidget);
    expect(find.byKey(LoginPage.passwordKey), findsOneWidget);
    expect(find.byKey(LoginPage.submitKey), findsOneWidget);
  });

  testWidgets(
    'si envÃ­o vacÃ­o, muestra errores de validaciÃ³n y no llama al repo',
    (tester) async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => makeLoginResult());

      await pumpLoginApp(tester, authRepository: repo);
      final l10n = l10nFor(tester);

      await tester.tap(find.byKey(LoginPage.submitKey));
      await tester.pumpAndSettle();

      expect(find.text(l10n.validationEmailEmpty), findsOneWidget);
      expect(find.text(l10n.validationPasswordEmpty), findsOneWidget);

      verifyNever(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  testWidgets('email invÃ¡lido muestra error y no llama al repo', (
    tester,
  ) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => makeLoginResult());

    await pumpLoginApp(tester, authRepository: repo);
    final l10n = l10nFor(tester);

    await tester.enterText(find.byKey(LoginPage.emailKey), 'no-es-email');
    await tester.enterText(find.byKey(LoginPage.passwordKey), '123456');

    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text(l10n.validationEmailInvalid), findsOneWidget);

    verifyNever(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('login correcto navega a Home y llama al repo con credenciales', (
    tester,
  ) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => makeLoginResult(token: 'abc'));

    final navObserver = MockNavigatorObserver();

    await pumpLoginApp(
      tester,
      authRepository: repo,
      navigatorObserver: navObserver,
    );

    await tester.enterText(find.byKey(LoginPage.emailKey), 'a@a.com');
    await tester.enterText(find.byKey(LoginPage.passwordKey), '123456');

    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('HOME_PAGE'), findsOneWidget);

    verify(() => repo.login(email: 'a@a.com', password: '123456')).called(1);

    verify(
      () => navObserver.didReplace(
        newRoute: any(named: 'newRoute'),
        oldRoute: any(named: 'oldRoute'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('login incorrecto muestra SnackBar con error y no navega', (
    tester,
  ) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(NetworkException('Bad credentials'));

    final navObserver = MockNavigatorObserver();

    await pumpLoginApp(
      tester,
      authRepository: repo,
      navigatorObserver: navObserver,
    );

    await tester.enterText(find.byKey(LoginPage.emailKey), 'a@a.com');
    await tester.enterText(find.byKey(LoginPage.passwordKey), 'wrongwrong');

    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Bad credentials'), findsOneWidget);

    verify(
      () => repo.login(email: 'a@a.com', password: 'wrongwrong'),
    ).called(1);

    verifyNever(
      () => navObserver.didReplace(
        newRoute: any(named: 'newRoute'),
        oldRoute: any(named: 'oldRoute'),
      ),
    );
  });
}
