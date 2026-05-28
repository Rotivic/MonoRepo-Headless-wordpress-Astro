import 'package:flutter/material.dart';
import 'brand_colors.dart';

abstract class AppThemeTokens {
  String? get fontFamily;
  ColorScheme get colorScheme;
  TextTheme get textTheme;
  InputDecorationTheme get inputDecorationTheme;
  FilledButtonThemeData get filledButtonTheme;
  OutlinedButtonThemeData get outlinedButtonTheme;
  CardThemeData get cardTheme;
  AppBarTheme get appBarTheme;
  DividerThemeData get dividerTheme;
}

class StripeThemeTokens implements AppThemeTokens {
  final Brightness brightness;

  StripeThemeTokens({required this.brightness});

  bool get isLight => brightness == Brightness.light;

  @override
  String? get fontFamily => 'Inter';

  @override
  ColorScheme get colorScheme => ColorScheme(
    brightness: brightness,
    primary: BrandColors.brand,
    onPrimary: BrandColors.white,
    secondary: isLight ? BrandColors.backgroundDark : BrandColors.brandLight,
    onSecondary: isLight ? BrandColors.white : BrandColors.backgroundDark,
    error: BrandColors.danger,
    onError: BrandColors.white,
    surface: isLight ? BrandColors.white : BrandColors.surfaceDark,
    onSurface: isLight ? BrandColors.backgroundDark : BrandColors.white,
    onSurfaceVariant: isLight ? BrandColors.textSecondary : Colors.white70,
    outline: isLight ? BrandColors.border : BrandColors.borderDark,
    outlineVariant: isLight ? const Color(0xFFD1DBE5) : const Color(0xFF3E4E61),
    surfaceContainerHighest: isLight
        ? const Color(0xFFF6F9FC)
        : BrandColors.backgroundDarker,
  );

  @override
  TextTheme get textTheme {
    final color = isLight ? BrandColors.backgroundDark : BrandColors.white;
    final bodyColor = isLight
        ? BrandColors.textSecondary
        : Colors.white.withOpacity(0.7);
    final fontFeatures = [FontFeature.stylisticSet(1)];

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        height: 1.03,
        letterSpacing: -1.4,
        color: color,
        fontFeatures: fontFeatures,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
        fontFeatures: fontFeatures,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w300,
        height: 1.2,
        color: color,
        fontFeatures: fontFeatures,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isLight
            ? BrandColors.textPrimary
            : Colors.white.withOpacity(0.9),
        fontFeatures: fontFeatures,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isLight ? BrandColors.brand : BrandColors.brandLight,
        letterSpacing: 1.2,
        fontFeatures: fontFeatures,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: fontFeatures,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: bodyColor,
        fontFeatures: fontFeatures,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isLight ? BrandColors.textSecondary : Colors.white54,
        fontFeatures: fontFeatures,
      ),
    );
  }

  @override
  InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: isLight
        ? BrandColors.white
        : BrandColors.surfaceDark.withOpacity(0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: isLight ? BrandColors.border : BrandColors.borderDark,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: isLight ? BrandColors.border : BrandColors.borderDark,
      ),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: BrandColors.brand, width: 2),
    ),
    hintStyle: TextStyle(
      color: isLight ? const Color(0x7764748D) : Colors.white30,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    prefixIconColor: isLight
        ? BrandColors.textSecondary.withOpacity(0.8)
        : Colors.white54,
    suffixIconColor: isLight
        ? BrandColors.textSecondary.withOpacity(0.8)
        : Colors.white54,
  );

  @override
  FilledButtonThemeData get filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: BrandColors.brand,
      foregroundColor: BrandColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 0,
    ),
  );

  @override
  OutlinedButtonThemeData get outlinedButtonTheme => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: isLight ? BrandColors.brand : BrandColors.brandLight,
      side: BorderSide(
        color: isLight ? const Color(0xFFD1DBE5) : BrandColors.borderDark,
      ),
      backgroundColor: isLight ? BrandColors.white : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
  );

  @override
  CardThemeData get cardTheme => CardThemeData(
    color: isLight ? BrandColors.white : BrandColors.backgroundDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
      side: BorderSide(
        color: isLight ? BrandColors.border : BrandColors.borderDark,
      ),
    ),
    elevation: 0,
  );

  @override
  AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: isLight ? BrandColors.backgroundDark : BrandColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w400,
    ),
    iconTheme: IconThemeData(
      color: isLight ? BrandColors.backgroundDark : BrandColors.white,
    ),
  );

  @override
  DividerThemeData get dividerTheme => DividerThemeData(
    color: isLight ? const Color(0xFFD1DBE5) : BrandColors.borderDark,
    thickness: 1,
    space: 1,
  );
}
