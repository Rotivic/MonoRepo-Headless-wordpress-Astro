import 'package:flutter/material.dart';

class AppShadows extends ThemeExtension<AppShadows> {
  final List<BoxShadow> standard;
  final List<BoxShadow> elevated;

  const AppShadows({
    required this.standard,
    required this.elevated,
  });

  @override
  ThemeExtension<AppShadows> copyWith({
    List<BoxShadow>? standard,
    List<BoxShadow>? elevated,
  }) {
    return AppShadows(
      standard: standard ?? this.standard,
      elevated: elevated ?? this.elevated,
    );
  }

  @override
  ThemeExtension<AppShadows> lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      standard: BoxShadow.lerpList(standard, other.standard, t)!,
      elevated: BoxShadow.lerpList(elevated, other.elevated, t)!,
    );
  }

  static const light = AppShadows(
    standard: [
      BoxShadow(
        color: Color(0x14171717), // rgba(23,23,23,0.08)
        offset: Offset(0, 15),
        blurRadius: 35,
      ),
    ],
    elevated: [
      BoxShadow(
        color: Color(0x4032325D), // rgba(50,50,93,0.25)
        offset: Offset(0, 30),
        blurRadius: 45,
        spreadRadius: -30,
      ),
      BoxShadow(
        color: Color(0x1A000000), // rgba(0,0,0,0.1)
        offset: Offset(0, 18),
        blurRadius: 36,
        spreadRadius: -18,
      ),
    ],
  );

  static const dark = AppShadows(
    standard: [
      BoxShadow(
        color: Color(0x33000000),
        offset: Offset(0, 15),
        blurRadius: 35,
      ),
    ],
    elevated: [
      BoxShadow(
        color: Color(0x66000000),
        offset: Offset(0, 30),
        blurRadius: 45,
        spreadRadius: -30,
      ),
    ],
  );
}
