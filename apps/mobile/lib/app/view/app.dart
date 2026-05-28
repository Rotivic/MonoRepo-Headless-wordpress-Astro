import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/app_settings/app_settings_cubit.dart';
import 'package:tcg_platform_mobile/core/network/api_client.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/register_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/login_page.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/recover_password_page.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/register_page.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/splash_page.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/two_factor_page.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/verify_email_page.dart';
import 'package:tcg_platform_mobile/features/main/presentation/view/main_page.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({
    required this.authRepository,
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final AuthRepository authRepository;
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: sessionStore),
        RepositoryProvider(
          create: (context) => ProfileRepository(
            context.read<ApiClient>(),
            context.read<SessionStore>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              context.read<SessionStore>(),
              context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AppSettingsCubit(context.read<SessionStore>()),
          ),
        ],
        child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, settings) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: settings.themeMode,
              locale: settings.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              initialRoute: AppRoutes.splash,
              routes: {
                AppRoutes.splash: (_) => const SplashPage(),
                AppRoutes.login: (context) => BlocProvider(
                  create: (context) => LoginCubit(
                    context.read<AuthRepository>(),
                    context.read<SessionStore>(),
                  ),
                  child: const LoginPage(),
                ),
                AppRoutes.register: (context) => BlocProvider(
                  create: (context) => RegisterCubit(
                    context.read<AuthRepository>(),
                    context.read<SessionStore>(),
                  ),
                  child: const RegisterPage(),
                ),
                AppRoutes.recoverPassword: (_) => const RecoverPasswordPage(),
                AppRoutes.verifyEmail: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as String?;
                  return VerifyEmailPage(email: args ?? '');
                },
                AppRoutes.twoFactor: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  return TwoFactorPage(
                    challengeToken: (args?['challenge_token'] as String?) ?? '',
                    email: (args?['email'] as String?) ?? '',
                    password: (args?['password'] as String?) ?? '',
                  );
                },
                AppRoutes.home: (_) => const MainPage(),
              },
            );
          },
        ),
      ),
    );
  }
}
