import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.fieldKey,
    this.enabled = true,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final Key? fieldKey;

  final String label;
  final TextEditingController controller;
  final IconData icon;

  final bool enabled;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final fill = cs.surfaceContainerHighest.withOpacity(0.55);
    final borderColor = cs.outlineVariant.withOpacity(0.55);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints?.toList(),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: fill,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),

        enabledBorder: border(borderColor),
        focusedBorder: border(cs.primary, 1.4),
        errorBorder: border(cs.error),
        focusedErrorBorder: border(cs.error, 1.4),
      ),
    );
  }
}
