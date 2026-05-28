import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/custom_text_field.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/login_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const emailKey = Key('login_email');
  static const passwordKey = Key('login_password');
  static const submitKey = Key('login_submit');

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _hidePassword = true;
  bool _showValidationErrors = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final isEmailValid = emailRegex.hasMatch(email);
    final isPasswordValid = password.isNotEmpty;

    setState(() {
      _isFormValid = isEmailValid && isPasswordValid;
    });
  }

  String? _emailValidator(String? value) {
    final l10n = context.l10n;
    final email = (value ?? '').trim();

    if (email.isEmpty) return l10n.validationEmailEmpty;

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) return l10n.validationEmailInvalid;

    return null;
  }

  String? _passwordValidator(String? value) {
    final l10n = context.l10n;
    final pass = value ?? '';

    if (pass.trim().isEmpty) return l10n.validationPasswordEmpty;
    if (pass.length < 6) return l10n.validationPasswordMin(6);

    return null;
  }

  void _onSubmitPressed({required bool isLoading}) {
    if (isLoading) return;

    setState(() => _showValidationErrors = true);
    final isOk = _formKey.currentState?.validate() ?? false;
    if (!isOk || !_isFormValid) return;

    FocusScope.of(context).unfocus();

    context.read<LoginCubit>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _focusPassword() => FocusScope.of(context).requestFocus(_passwordFocus);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is LoginTwoFactorRequired) {
          Navigator.of(context).pushNamed(
            AppRoutes.twoFactor,
            arguments: {
              'challenge_token': state.challengeToken,
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            },
          );
        }

        if (state is LoginSuccess) {
          context.read<AuthCubit>().setAuthenticated(state.user);

          final authState = context.read<AuthCubit>().state;
          if (authState is AuthNeedsVerification) {
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.verifyEmail,
              arguments: state.user.email,
            );
          } else {
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.home,
              arguments: state.user,
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;

        return Scaffold(
          body: AuthBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.x32,
                    vertical: spacing.x24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _showValidationErrors
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),

                          SizedBox(height: spacing.headerGap),

                          CustomTextField(
                            fieldKey: LoginPage.emailKey,
                            label: l10n.loginEmailLabel,
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            focusNode: _emailFocus,
                            autofillHints: const [AutofillHints.username],
                            validator: _emailValidator,
                            onFieldSubmitted: (_) => _focusPassword(),
                            hintText: 'example@gmail.com',
                          ),

                          SizedBox(height: spacing.fieldGap),

                          CustomTextField(
                            fieldKey: LoginPage.passwordKey,
                            label: l10n.loginPasswordLabel,
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            enabled: !isLoading,
                            obscureText: _hidePassword,
                            isPassword: true,
                            onSuffixIconTap: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            textInputAction: TextInputAction.done,
                            focusNode: _passwordFocus,
                            autofillHints: const [AutofillHints.password],
                            validator: _passwordValidator,
                            onFieldSubmitted: (_) =>
                                _onSubmitPressed(isLoading: isLoading),
                            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                          ),

                          SizedBox(height: spacing.x12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.recoverPassword);
                                    },
                              child: Text(
                                l10n.loginForgotPassword,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: spacing.x24),

                          FilledButton(
                            key: LoginPage.submitKey,
                            onPressed: isLoading
                                ? null
                                : () => _onSubmitPressed(isLoading: isLoading),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.loginSignInCta),
                          ),

                          SizedBox(height: spacing.x24),

                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.register),
                            child: Text(l10n.loginCreateNewAccount),
                          ),

                          SizedBox(height: spacing.sectionGap),

                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.x16,
                                ),
                                child: Text(
                                  l10n.loginOrContinueWith,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          SizedBox(height: spacing.x24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialIcon(
                                onPressed: () {},
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing.x16),
                              _SocialIcon(
                                onPressed: () {},
                                child: const Icon(Icons.facebook),
                              ),
                              SizedBox(width: spacing.x16),
                              _SocialIcon(
                                onPressed: () {},
                                child: const Icon(Icons.apple),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          l10n.loginHeaderTitle.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.loginHeaderSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium,
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.child, required this.onPressed});

  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: theme.outlinedButtonTheme.style,
        child: IconTheme(
          data: IconThemeData(color: theme.colorScheme.onSurface),
          child: DefaultTextStyle(
            style: TextStyle(color: theme.colorScheme.onSurface),
            child: child,
          ),
        ),
      ),
    );
  }
}
