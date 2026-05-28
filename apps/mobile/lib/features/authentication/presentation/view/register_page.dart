import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/custom_text_field.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/register_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/register_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();

  bool _hidePassword = true;
  bool _hidePasswordAgain = true;
  bool _showValidationErrors = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  bool _hasMinLength(String value) => value.length >= 12;
  bool _hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);
  bool _hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  bool _hasSpecialChar(String value) =>
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]').hasMatch(value);

  int _passwordScore(String value) {
    var score = 0;
    if (_hasMinLength(value)) score++;
    if (_hasLowercase(value)) score++;
    if (_hasUppercase(value)) score++;
    if (_hasSpecialChar(value)) score++;
    return score;
  }

  double _passwordProgress(String value) => _passwordScore(value) / 4;

  Color _passwordStrengthColor(String value) {
    final score = _passwordScore(value);
    if (score <= 1) return Colors.redAccent;
    if (score == 2) return Colors.orangeAccent;
    if (score == 3) return Colors.amber.shade700;
    return Colors.green;
  }

  String _passwordStrengthLabel(BuildContext context, String value) {
    final l10n = context.l10n;
    final score = _passwordScore(value);
    if (score <= 1) return l10n.passwordStrengthWeak;
    if (score == 2) return l10n.passwordStrengthMedium;
    if (score == 3) return l10n.passwordStrengthGood;
    return l10n.passwordStrengthStrong;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.validationFieldEmpty;
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return context.l10n.validationEmailEmpty;

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) return context.l10n.validationEmailInvalid;

    return null;
  }

  String? _passwordValidator(String? value) {
    final pass = value ?? '';
    if (pass.isEmpty) return context.l10n.validationPasswordEmpty;
    if (!_hasMinLength(pass)) return context.l10n.validationPasswordMin(12);
    return null;
  }

  String? _passwordAgainValidator(String? value) {
    if (value == null || value.isEmpty)
      return context.l10n.validationFieldEmpty;
    if (value != _passwordController.text) {
      return context.l10n.validationPasswordsNotMatch;
    }
    return null;
  }

  void _onRegisterPressed() {
    final isOk = _formKey.currentState?.validate() ?? false;
    if (!isOk) {
      setState(() => _showValidationErrors = true);
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<RegisterCubit>().register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordAgainController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final password = _passwordController.text;
    final strengthColor = _passwordStrengthColor(password);

    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is RegisterSuccess) {
          context.read<AuthCubit>().setAuthenticated(state.user);

          final authState = context.read<AuthCubit>().state;
          if (authState is AuthNeedsVerification) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.verifyEmail,
              (route) => false,
              arguments: state.user.email,
            );
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
              arguments: state.user,
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is RegisterLoading;

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
                      onChanged: _validateForm,
                      autovalidateMode: _showValidationErrors
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          SizedBox(height: spacing.headerGap),
                          CustomTextField(
                            label: l10n.registerFirstNameLabel,
                            controller: _firstNameController,
                            icon: Icons.person_outline,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                            hintText: 'John',
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.registerLastNameLabel,
                            controller: _lastNameController,
                            icon: Icons.person_outline,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                            hintText: 'Doe',
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.registerEmailLabel,
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _emailValidator,
                            hintText: 'example@gmail.com',
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.registerPasswordLabel,
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            enabled: !isLoading,
                            obscureText: _hidePassword,
                            isPassword: true,
                            onSuffixIconTap: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            textInputAction: TextInputAction.next,
                            validator: _passwordValidator,
                            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                          ),
                          SizedBox(height: spacing.x16),
                          _PasswordStrengthCard(
                            progress: _passwordProgress(password),
                            color: strengthColor,
                            label: _passwordStrengthLabel(context, password),
                            hasMinLength: _hasMinLength(password),
                            hasLowercase: _hasLowercase(password),
                            hasUppercase: _hasUppercase(password),
                            hasSpecialChar: _hasSpecialChar(password),
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.registerPasswordAgainLabel,
                            controller: _passwordAgainController,
                            icon: Icons.lock_reset_outlined,
                            enabled: !isLoading,
                            obscureText: _hidePasswordAgain,
                            isPassword: true,
                            onSuffixIconTap: () => setState(
                              () => _hidePasswordAgain = !_hidePasswordAgain,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: _passwordAgainValidator,
                            onFieldSubmitted: (_) =>
                                _isFormValid ? _onRegisterPressed() : null,
                            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                          ),
                          SizedBox(height: spacing.x32),
                          FilledButton(
                            onPressed: (isLoading || !_isFormValid)
                                ? null
                                : _onRegisterPressed,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.registerSubmitCta),
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
          l10n.registerTitle.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.registerSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium,
        ),
      ],
    );
  }
}

class _PasswordStrengthCard extends StatelessWidget {
  const _PasswordStrengthCard({
    required this.progress,
    required this.color,
    required this.label,
    required this.hasMinLength,
    required this.hasLowercase,
    required this.hasUppercase,
    required this.hasSpecialChar,
  });

  final double progress;
  final Color color;
  final String label;
  final bool hasMinLength;
  final bool hasLowercase;
  final bool hasUppercase;
  final bool hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(spacing.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: color,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    minHeight: 4,
                  ),
                ),
              ),
              SizedBox(width: spacing.x12),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.x12),
          _RequirementRow(
            label: l10n.passwordRequirementLength,
            isMet: hasMinLength,
          ),
          _RequirementRow(
            label: l10n.passwordRequirementLowercase,
            isMet: hasLowercase,
          ),
          _RequirementRow(
            label: l10n.passwordRequirementUppercase,
            isMet: hasUppercase,
          ),
          _RequirementRow(
            label: l10n.passwordRequirementSpecial,
            isMet: hasSpecialChar,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.isMet});
  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.x6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          SizedBox(width: theme.spacing.x8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMet
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
