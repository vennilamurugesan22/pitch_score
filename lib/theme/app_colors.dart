import 'package:flutter/material.dart';

// One set of colors per theme. AppColors reads from whichever is active,
// so screens keep using AppColors.x and pick up theme changes on rebuild.
class AppPalette {
  final Brightness brightness;

  // Background layers
  final Color background;
  final Color surface;
  final Color surfaceLight;

  // Accent colors (xDark = tinted fill behind the accent)
  final Color green;
  final Color greenDark;
  final Color blue;
  final Color blueDark;
  final Color red;
  final Color redDark;
  final Color amber;
  final Color amberDark;

  // Text / icons drawn on top of a solid accent (e.g. green buttons)
  final Color onAccent;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // Border
  final Color border;
  final Color borderLight;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.green,
    required this.greenDark,
    required this.blue,
    required this.blueDark,
    required this.red,
    required this.redDark,
    required this.amber,
    required this.amberDark,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.borderLight,
  });

  // Night stadium — neon green on deep navy
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F0F1A),
    surface: Color(0xFF1A1A2E),
    surfaceLight: Color(0xFF1E2A3A),
    green: Color(0xFF00C853),
    greenDark: Color(0xFF003020),
    blue: Color(0xFF29B6F6),
    blueDark: Color(0xFF0A1A3A),
    red: Color(0xFFEF5350),
    redDark: Color(0xFF3A0A0A),
    amber: Color(0xFFFFB300),
    amberDark: Color(0xFF3A2A0A),
    onAccent: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
    textHint: Color(0xFF444444),
    border: Color(0xFF2A2A3E),
    borderLight: Color(0xFF333333),
  );

  // Day match — deep pitch green on soft mint-white. Accents are darker than
  // the dark theme's so text stays readable (≥4.5:1) on white in the sun.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF2F5F3),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE6ECE8),
    green: Color(0xFF0A7F41),
    greenDark: Color(0xFFE0F2E7),
    blue: Color(0xFF1565C0),
    blueDark: Color(0xFFE3EEFB),
    red: Color(0xFFC62828),
    redDark: Color(0xFFFCE8E8),
    amber: Color(0xFFB45309),
    amberDark: Color(0xFFFFF1DC),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF5B6472),
    textHint: Color(0xFF9AA3AE),
    border: Color(0xFFDDE3DF),
    borderLight: Color(0xFFCDD5D0),
  );
}

class AppColors {
  // Swapped by ThemeController; dark is the default
  static AppPalette palette = AppPalette.dark;

  static bool get isDark => palette.brightness == Brightness.dark;

  // Background layers
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get surfaceLight => palette.surfaceLight;

  // Accent colors
  static Color get green => palette.green;
  static Color get greenDark => palette.greenDark;
  static Color get blue => palette.blue;
  static Color get blueDark => palette.blueDark;
  static Color get red => palette.red;
  static Color get redDark => palette.redDark;
  static Color get amber => palette.amber;
  static Color get amberDark => palette.amberDark;
  static Color get onAccent => palette.onAccent;

  // Text
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textHint => palette.textHint;

  // Border
  static Color get border => palette.border;
  static Color get borderLight => palette.borderLight;
}
