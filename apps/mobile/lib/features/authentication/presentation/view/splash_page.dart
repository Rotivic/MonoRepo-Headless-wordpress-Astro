import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Image _logoImage;
  final Completer<void> _imageCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();

    _logoImage = Image.asset(
      'assets/images/logo_signlab.png',
      fit: BoxFit.contain,
    );

    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    precacheImage(_logoImage.image, context)
        .then((_) {
          if (!_imageCompleter.isCompleted) {
            _imageCompleter.complete();
          }
        })
        .catchError((Object error) {
          if (!_imageCompleter.isCompleted) {
            _imageCompleter.complete();
          }
        });
  }

  Future<void> _init() async {
    final minimumSplashDuration = Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    await context.read<AuthCubit>().initialize();

    await Future.wait([
      minimumSplashDuration,
      _imageCompleter.future,
    ]);

    FlutterNativeSplash.remove();

    if (!mounted) return;

    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
        arguments: authState.user,
      );
    } else if (authState is AuthNeedsVerification) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.verifyEmail,
        arguments: authState.user.email,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el color de superficie del tema (se adaptarÃ¡ a Dark/Light Mode)
    final themeBackground = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: themeBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: _logoImage,
          ),
        ),
      ),
    );
  }
}
