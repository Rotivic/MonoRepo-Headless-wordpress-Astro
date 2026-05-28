import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/theme/app_shadows.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';
import 'package:tcg_platform_mobile/theme/theme_tokens.dart';

class AppTheme {
  static ThemeData create({
    required Brightness brightness,
    AppThemeTokens? tokens,
  }) {
    final t = tokens ?? StripeThemeTokens(brightness: brightness);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: t.fontFamily,
      colorScheme: t.colorScheme,
      textTheme: t.textTheme,
      inputDecorationTheme: t.inputDecorationTheme,
      filledButtonTheme: t.filledButtonTheme,
      outlinedButtonTheme: t.outlinedButtonTheme,
      cardTheme: t.cardTheme,
      appBarTheme: t.appBarTheme,
      dividerTheme: t.dividerTheme,
      scaffoldBackgroundColor: t.colorScheme.surface,

      extensions: [
        brightness == Brightness.light ? AppShadows.light : AppShadows.dark,
        AppSpacing.stripe, // Inyectamos los espacios como extensiÃ³n
      ],
    );

    return base.copyWith(
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() => create(brightness: Brightness.light);
  static ThemeData dark() => create(brightness: Brightness.dark);
}
