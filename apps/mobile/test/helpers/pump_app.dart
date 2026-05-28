import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/login_page.dart';
import 'package:tcg_platform_mobile/l10n/gen/app_localizations.dart';
import 'package:tcg_platform_mobile/theme/app_theme.dart';

import 'mocks.dart';

Future<void> pumpLoginApp(
  WidgetTester tester, {
  required AuthRepository authRepository,
  SessionStore? sessionStore,
  NavigatorObserver? navigatorObserver,
  Widget? homePage,
}) async {
  final storage = MockSecureStorage();
  when(
    () => storage.read(key: any(named: 'key')),
  ).thenAnswer((_) async => null);
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((_) async {});
  when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

  final store = sessionStore ?? SessionStore(storage);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: store),
      ],
      child: BlocProvider(
        create: (context) => AuthCubit(
          context.read<SessionStore>(),
          context.read<AuthRepository>(),
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [
            if (navigatorObserver != null) navigatorObserver,
          ],
          initialRoute: AppRoutes.login,
          routes: {
            AppRoutes.login: (context) => BlocProvider(
              create: (_) => LoginCubit(
                context.read<AuthRepository>(),
                context.read<SessionStore>(),
              ),
              child: const LoginPage(),
            ),
            AppRoutes.home: (_) =>
                homePage ??
                const Scaffold(body: Center(child: Text('HOME_PAGE'))),
          },
        ),
      ),
    ),
  );

  await tester.pump();
}
