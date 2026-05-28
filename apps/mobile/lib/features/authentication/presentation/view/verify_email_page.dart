import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/verify_email_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/verify_email_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({
    required this.email,
    super.key,
  });

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VerifyEmailCubit(
        context.read<AuthRepository>(),
        context.read<SessionStore>(),
      ),
      child: _VerifyEmailView(email: email),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView({required this.email});

  final String email;

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    for (final c in _otpControllers) {
      c.addListener(_validateForm);
    }
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.removeListener(_validateForm);
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _validateForm() {
    final code = _otpControllers.map((e) => e.text).join();
    setState(() {
      _isFormValid = code.length == 6;
    });
  }

  void _onVerifyPressed() {
    if (!_isFormValid) return;

    final code = _otpControllers.map((e) => e.text).join();
    context.read<VerifyEmailCubit>().verifyCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;

    return BlocListener<VerifyEmailCubit, VerifyEmailState>(
      listener: (context, state) async {
        if (state is VerifyEmailError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is VerifyEmailSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is VerifyEmailVerified) {
          await context.read<AuthCubit>().initialize();
          if (!context.mounted) return;

          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        }
      },
      child: Scaffold(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      SizedBox(height: spacing.headerGap),
                      Text(
                        l10n.verifyEmailSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: spacing.x12),
                      Text(
                        l10n.verifyEmailLabel(widget.email),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: spacing.sectionGap),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return _OtpDigitField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }

                              if (index == 5 &&
                                  value.isNotEmpty &&
                                  _isFormValid) {
                                FocusScope.of(context).unfocus();
                                _onVerifyPressed();
                              }
                            },
                          );
                        }),
                      ),

                      SizedBox(height: spacing.sectionGap),

                      BlocBuilder<VerifyEmailCubit, VerifyEmailState>(
                        builder: (context, state) {
                          final isLoading = state is VerifyEmailLoading;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: (isLoading || !_isFormValid)
                                    ? null
                                    : _onVerifyPressed,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Verificar cÃ³digo'),
                              ),
                              SizedBox(height: spacing.x16),
                              OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context
                                          .read<VerifyEmailCubit>()
                                          .resendEmail(),
                                child: Text(l10n.verifyEmailResendCta),
                              ),
                              SizedBox(height: spacing.x12),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context
                                          .read<VerifyEmailCubit>()
                                          .checkVerificationStatus(),
                                child: Text(l10n.verifyEmailConfirmedCta),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: spacing.headerGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.read<AuthCubit>().logout();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                            },
                            child: Text(l10n.verifyEmailGoBack),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<AuthCubit>().logout();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                            },
                            child: Text(
                              l10n.verifyEmailLogout,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
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
          l10n.verifyEmailTitle.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.verifyEmailTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 32),
        ),
      ],
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
