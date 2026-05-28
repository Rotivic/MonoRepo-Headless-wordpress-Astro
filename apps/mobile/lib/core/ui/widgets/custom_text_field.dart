import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
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
    this.isPassword = false,
    this.onSuffixIconTap,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.hintText,
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

  final bool isPassword;
  final VoidCallback? onSuffixIconTap;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
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
          textAlign: textAlign,
          inputFormatters: inputFormatters,
          style: theme.textTheme.bodyLarge, // Texto que se escribe
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon:
                suffix ??
                (isPassword
                    ? IconButton(
                        onPressed: onSuffixIconTap,
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      )
                    : null),
          ),
        ),
      ],
    );
  }
}
