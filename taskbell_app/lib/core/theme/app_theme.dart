import 'package:flutter/material.dart';

/// Warna semantik yang berubah antara mode terang dan gelap.
/// Widget membaca nilai ini lewat `AppPalette.of(context)` agar tidak ada
/// warna permukaan yang di-hardcode.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.border,
    required this.shadow,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.secondary,
    required this.onAccent,
    required this.secondarySoft,
    required this.error,
    required this.errorSoft,
    required this.success,
    required this.successSoft,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color border;
  final Color shadow;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color secondary;
  final Color onAccent;
  final Color secondarySoft;
  final Color error;
  final Color errorSoft;
  final Color success;
  final Color successSoft;

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? light;
  }

  static const AppPalette light = AppPalette(
    canvas: Color(0xFFFFF9EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2EFE7),
    ink: Color(0xFF171717),
    muted: Color(0xFF555555),
    border: Color(0xFF171717),
    shadow: Color(0xFF171717),
    primary: Color(0xFF0059B9),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFACC7FF),
    secondary: Color(0xFFFDB700),
    onAccent: Color(0xFF171717),
    secondarySoft: Color(0xFFFFDEA7),
    error: Color(0xFFB42335),
    errorSoft: Color(0xFFFFDAD6),
    success: Color(0xFF197447),
    successSoft: Color(0xFFB7F2CF),
  );

  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF101216),
    surface: Color(0xFF1B1F24),
    surfaceAlt: Color(0xFF262B31),
    ink: Color(0xFFF4F1EA),
    muted: Color(0xFFB9B3A8),
    border: Color(0xFFE9E3D7),
    shadow: Color(0xFF000000),
    primary: Color(0xFF8AB4FF),
    onPrimary: Color(0xFF0B1220),
    primarySoft: Color(0xFF1F3A66),
    secondary: Color(0xFFFFC94D),
    onAccent: Color(0xFF171717),
    secondarySoft: Color(0xFF4A3A12),
    error: Color(0xFFFF8A80),
    errorSoft: Color(0xFF4A1F22),
    success: Color(0xFF7FE0A6),
    successSoft: Color(0xFF143A26),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? muted,
    Color? border,
    Color? shadow,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? secondary,
    Color? onAccent,
    Color? secondarySoft,
    Color? error,
    Color? errorSoft,
    Color? success,
    Color? successSoft,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      onAccent: onAccent ?? this.onAccent,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;

    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
    );
  }
}

class AppTheme {
  static final ThemeData lightTheme =
      _build(AppPalette.light, Brightness.light);
  static final ThemeData darkTheme = _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0059B9),
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onAccent,
      surface: palette.surface,
      onSurface: palette.ink,
      error: palette.error,
      outline: palette.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.canvas,
      colorScheme: scheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w900,
          fontVariations: const [FontVariation('wght', 900)],
          color: palette.ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: palette.ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.bold,
          fontVariations: const [FontVariation('wght', 700)],
          color: palette.ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontVariations: const [FontVariation('wght', 400)],
          color: palette.ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontVariations: const [FontVariation('wght', 400)],
          color: palette.ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceAlt,
        contentTextStyle: TextStyle(color: palette.ink),
      ),
      dividerColor: palette.border,
    );
  }
}
