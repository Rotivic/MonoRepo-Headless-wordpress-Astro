import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/custom_text_field.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/recover_password_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/recover_password_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _showValidationErrors = false;
  bool _emailSent = false;
  String _successMessage = '';
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    setState(() {
      _isFormValid = emailRegex.hasMatch(email);
    });
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RecoverPasswordCubit>().forgotPassword(
        _emailController.text.trim(),
      );
    } else {
      setState(() => _showValidationErrors = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return BlocProvider(
      create: (context) => RecoverPasswordCubit(context.read<AuthRepository>()),
      child: BlocConsumer<RecoverPasswordCubit, RecoverPasswordState>(
        listener: (context, state) {
          if (state is RecoverPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is RecoverPasswordCodeSent) {
            setState(() {
              _emailSent = true;
              _successMessage = state.message;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is RecoverPasswordLoading;

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
                      child: _emailSent
                          ? _SuccessView(
                              message: _successMessage,
                              email: _emailController.text,
                            )
                          : Form(
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
                                    label: l10n.loginEmailLabel,
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if ((value ?? '').isEmpty)
                                        return l10n.validationEmailEmpty;
                                      final emailRegex = RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      );
                                      if (!emailRegex.hasMatch(value!))
                                        return l10n.validationEmailInvalid;
                                      return null;
                                    },
                                    hintText: 'example@gmail.com',
                                  ),
                                  SizedBox(height: spacing.x32),
                                  FilledButton(
                                    onPressed: (isLoading || !_isFormValid)
                                        ? null
                                        : () => _onSubmit(context),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(l10n.recoverPasswordGetCodeCta),
                                  ),
                                  SizedBox(height: spacing.x24),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    child: Text(l10n.twoFactorBackToLogin),
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
          l10n.recoverPasswordTitle.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.recoverPasswordGetCodeMsg,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.message,
    required this.email,
  });

  final String message;
  final String email;

  Future<void> _launchEmailApp() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(spacing.x24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 64,
            color: Colors.green,
          ),
        ),
        SizedBox(height: spacing.x32),
        Text(
          'Â¡Email enviado!',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.x12),
        Text(
          message,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.x8),
        Text(
          email,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.headerGap),
        FilledButton.icon(
          onPressed: _launchEmailApp,
          icon: const Icon(Icons.mail_outline),
          label: const Text('Abrir mi correo'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        SizedBox(height: spacing.x24),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver al login'),
        ),
      ],
    );
  }
}
