import 'package:flutter/material.dart';

/// Central visual language for Ember Ascent.
///
/// Replaces the previous `google_fonts` dependency: we lean on the platform
/// system typeface (San Francisco on iOS) and express identity through weight,
/// spacing and the ember colour ramp instead of a downloaded font.
class Palette {
  Palette._();

  static const Color ink = Color(0xFF12060A);
  static const Color charcoal = Color(0xFF1F0B07);
  static const Color ember = Color(0xFFFF6D00);
  static const Color emberHot = Color(0xFFFF3D00);
  static const Color emberDeep = Color(0xFFB71C1C);
  static const Color gold = Color(0xFFFFD54A);
  static const Color cream = Color(0xFFFFF1D6);
  static const Color cool = Color(0xFF4FC3F7);
  static const Color danger = Color(0xFFFF1744);
  static const Color steady = Color(0xFF7CFC8A);

  static const List<Color> emberRamp = [
    Color(0xFFFFF176),
    Color(0xFFFFB300),
    Color(0xFFFF6D00),
    Color(0xFFE53900),
  ];
}

/// Typography helpers. Every label in the game funnels through here so the
/// look stays consistent without a third-party font package.
class AppText {
  AppText._();

  static const String _family = '.SF Pro Display';

  static TextStyle display(double size, {Color color = Palette.gold}) =>
      TextStyle(
        fontFamilyFallback: const [_family, 'Roboto'],
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: size * 0.04,
        color: color,
        height: 1.05,
        shadows: const [
          Shadow(color: Palette.emberHot, blurRadius: 14),
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  static TextStyle title(double size, {Color color = Palette.cream}) =>
      TextStyle(
        fontFamilyFallback: const [_family, 'Roboto'],
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.06,
        color: color,
        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
      );

  static TextStyle label(double size,
          {Color color = Palette.cream, double spacing = 1.5}) =>
      TextStyle(
        fontFamilyFallback: const [_family, 'Roboto'],
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
        color: color,
      );

  static TextStyle body(double size, {Color? color}) => TextStyle(
        fontFamilyFallback: const [_family, 'Roboto'],
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? Colors.white.withValues(alpha: 0.78),
        height: 1.25,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Palette.ink,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.ember,
      brightness: Brightness.dark,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
