import 'package:flutter/material.dart';

class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.x1,
    required this.x2,
    required this.x4,
    required this.x6,
    required this.x8,
    required this.x10,
    required this.x12,
    required this.x14,
    required this.x16,
    required this.x18,
    required this.x20,
    required this.x24,
    required this.x32,
    required this.x40,
    required this.x48,
    required this.x64,
  });

  final double x1;
  final double x2;
  final double x4;
  final double x6;
  final double x8;
  final double x10;
  final double x12;
  final double x14;
  final double x16;
  final double x18;
  final double x20;
  final double x24;
  final double x32;
  final double x40;
  final double x48;
  final double x64;

  // Semantic Gaps
  double get fieldGap => x24;
  double get sectionGap => x48;
  double get headerGap => x48;

  @override
  ThemeExtension<AppSpacing> copyWith({
    double? x1,
    double? x2,
    double? x4,
    double? x6,
    double? x8,
    double? x10,
    double? x12,
    double? x14,
    double? x16,
    double? x18,
    double? x20,
    double? x24,
    double? x32,
    double? x40,
    double? x48,
    double? x64,
  }) {
    return AppSpacing(
      x1: x1 ?? this.x1,
      x2: x2 ?? this.x2,
      x4: x4 ?? this.x4,
      x6: x6 ?? this.x6,
      x8: x8 ?? this.x8,
      x10: x10 ?? this.x10,
      x12: x12 ?? this.x12,
      x14: x14 ?? this.x14,
      x16: x16 ?? this.x16,
      x18: x18 ?? this.x18,
      x20: x20 ?? this.x20,
      x24: x24 ?? this.x24,
      x32: x32 ?? this.x32,
      x40: x40 ?? this.x40,
      x48: x48 ?? this.x48,
      x64: x64 ?? this.x64,
    );
  }

  @override
  ThemeExtension<AppSpacing> lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      x1: lerpDouble(x1, other.x1, t)!,
      x2: lerpDouble(x2, other.x2, t)!,
      x4: lerpDouble(x4, other.x4, t)!,
      x6: lerpDouble(x6, other.x6, t)!,
      x8: lerpDouble(x8, other.x8, t)!,
      x10: lerpDouble(x10, other.x10, t)!,
      x12: lerpDouble(x12, other.x12, t)!,
      x14: lerpDouble(x14, other.x14, t)!,
      x16: lerpDouble(x16, other.x16, t)!,
      x18: lerpDouble(x18, other.x18, t)!,
      x20: lerpDouble(x20, other.x20, t)!,
      x24: lerpDouble(x24, other.x24, t)!,
      x32: lerpDouble(x32, other.x32, t)!,
      x40: lerpDouble(x40, other.x40, t)!,
      x48: lerpDouble(x48, other.x48, t)!,
      x64: lerpDouble(x64, other.x64, t)!,
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    return ((a ?? 0) + ((b ?? 0) - (a ?? 0)) * t).toDouble();
  }

  static const stripe = AppSpacing(
    x1: 1,
    x2: 2,
    x4: 4,
    x6: 6,
    x8: 8,
    x10: 10,
    x12: 12,
    x14: 14,
    x16: 16,
    x18: 18,
    x20: 20,
    x24: 24,
    x32: 32,
    x40: 40,
    x48: 48,
    x64: 64,
  );
}

// Extension to make it easier to access spacing from Theme
extension AppSpacingTheme on ThemeData {
  AppSpacing get spacing => extension<AppSpacing>() ?? AppSpacing.stripe;
}
