import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/custom_text_field.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/change_password_cubit.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/change_password_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChangePasswordCubit(context.read<ProfileRepository>()),
      child: const ChangePasswordView(),
    );
  }
}

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _oldPasswordController.addListener(_validateForm);
    _newPasswordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    setState(() {
      _isFormValid =
          oldPass.isNotEmpty &&
          _isPasswordSecure(newPass) &&
          newPass == confirmPass &&
          newPass != oldPass;
    });
  }

  bool _hasMinLength(String value) => value.length >= 6;
  bool _hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);
  bool _hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  bool _hasSpecialChar(String value) =>
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]').hasMatch(value);

  bool _isPasswordSecure(String value) {
    return _hasMinLength(value) &&
        _hasLowercase(value) &&
        _hasUppercase(value) &&
        _hasSpecialChar(value);
  }

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

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ChangePasswordCubit>().changePassword(
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final newPassword = _newPasswordController.text;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
            listener: (context, state) {
              if (state is ChangePasswordSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else if (state is ChangePasswordError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is ChangePasswordLoading;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.x32,
                    vertical: spacing.x24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          SizedBox(height: spacing.headerGap),
                          CustomTextField(
                            label: l10n.changePasswordCurrentLabel,
                            controller: _oldPasswordController,
                            isPassword: true,
                            obscureText: _obscureOld,
                            icon: Icons.lock_outline_rounded,
                            onSuffixIconTap: () =>
                                setState(() => _obscureOld = !_obscureOld),
                            enabled: !isLoading,
                            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.changePasswordNewLabel,
                            controller: _newPasswordController,
                            isPassword: true,
                            obscureText: _obscureNew,
                            icon: Icons.vpn_key_outlined,
                            onSuffixIconTap: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            enabled: !isLoading,
                            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                          ),
                          SizedBox(height: spacing.x16),
                          _PasswordStrengthCard(
                            progress: _passwordProgress(newPassword),
                            color: _passwordStrengthColor(newPassword),
                            label: _passwordStrengthLabel(context, newPassword),
                            hasMinLength: _hasMinLength(newPassword),
                            hasLowercase: _hasLowercase(newPassword),
                            hasUppercase: _hasUppercase(newPassword),
                            hasSpecialChar: _hasSpecialChar(newPassword),
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.changePasswordConfirmLabel,
                            controller: _confirmPasswordController,
                            isPassword: true,
                            obscureText: _obscureConfirm,
                            icon: Icons.vpn_key_rounded,
                            onSuffixIconTap: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            enabled: !isLoading,
                            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                            validator: (value) {
                              if (value != _newPasswordController.text) {
                                return l10n.changePasswordMatchError;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: spacing.sectionGap),
                          FilledButton(
                            onPressed: (isLoading || !_isFormValid)
                                ? null
                                : _onSave,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.changePasswordSubmitCta),
                          ),
                          SizedBox(height: spacing.x24),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(l10n.commonBack),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      children: [
        Text(
          l10n.profileSectionSecurity.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.changePasswordTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 32),
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
