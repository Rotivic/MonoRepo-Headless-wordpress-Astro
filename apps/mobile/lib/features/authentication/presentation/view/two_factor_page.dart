import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/custom_text_field.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/two_factor_cubit.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/two_factor_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class TwoFactorPage extends StatelessWidget {
  const TwoFactorPage({
    required this.challengeToken,
    required this.email,
    required this.password,
    super.key,
  });

  final String challengeToken;
  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TwoFactorCubit(
        context.read<AuthRepository>(),
        context.read<SessionStore>(),
      ),
      child: _TwoFactorView(
        challengeToken: challengeToken,
        email: email,
        password: password,
      ),
    );
  }
}

class _TwoFactorView extends StatefulWidget {
  const _TwoFactorView({
    required this.challengeToken,
    required this.email,
    required this.password,
  });

  final String challengeToken;
  final String email;
  final String password;

  @override
  State<_TwoFactorView> createState() => _TwoFactorViewState();
}

class _TwoFactorViewState extends State<_TwoFactorView> {
  bool _useRecoveryCode = false;
  bool _isFormValid = false;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final _recoveryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in _otpControllers) {
      c.addListener(_validateForm);
    }
    _recoveryController.addListener(_validateForm);
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
    _recoveryController.removeListener(_validateForm);
    _recoveryController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool valid = false;
    if (_useRecoveryCode) {
      valid = _recoveryController.text.trim().isNotEmpty;
    } else {
      final code = _otpControllers.map((e) => e.text).join();
      valid = code.length == 6;
    }
    if (mounted) setState(() => _isFormValid = valid);
  }

  void _onVerifyPressed() {
    if (!_isFormValid) return;

    final cubit = context.read<TwoFactorCubit>();
    if (_useRecoveryCode) {
      cubit.verify(
        challengeToken: widget.challengeToken,
        email: widget.email,
        password: widget.password,
        recoveryCode: _recoveryController.text.trim(),
      );
    } else {
      final code = _otpControllers.map((e) => e.text).join();
      cubit.verify(
        challengeToken: widget.challengeToken,
        email: widget.email,
        password: widget.password,
        code: code,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    return BlocListener<TwoFactorCubit, TwoFactorState>(
      listener: (context, state) {
        if (state is TwoFactorError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is TwoFactorSuccess) {
          context.read<AuthCubit>().setAuthenticated(state.user);
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
            arguments: state.user,
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

                      Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: l10n.twoFactorAppCodeTab,
                              isSelected: !_useRecoveryCode,
                              onPressed: () {
                                setState(() => _useRecoveryCode = false);
                                _validateForm();
                              },
                            ),
                          ),
                          SizedBox(width: spacing.x12),
                          Expanded(
                            child: _TabButton(
                              label: l10n.twoFactorRecoveryCodeTab,
                              isSelected: _useRecoveryCode,
                              onPressed: () {
                                setState(() => _useRecoveryCode = true);
                                _validateForm();
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing.x32),

                      if (!_useRecoveryCode)
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
                        )
                      else
                        CustomTextField(
                          label: l10n.twoFactorRecoveryCodeLabel,
                          controller: _recoveryController,
                          icon: Icons.vpn_key_outlined,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _isFormValid ? _onVerifyPressed() : null,
                          hintText: 'ABCD-1234',
                        ),

                      SizedBox(height: spacing.x32),

                      BlocBuilder<TwoFactorCubit, TwoFactorState>(
                        builder: (context, state) {
                          final isLoading = state is TwoFactorLoading;
                          return FilledButton(
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
                                : Text(l10n.twoFactorSubmitCta),
                          );
                        },
                      ),

                      SizedBox(height: spacing.x24),

                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
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
          l10n.twoFactorTitle.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.twoFactorSubtitle,
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

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return isSelected
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          );
  }
}
