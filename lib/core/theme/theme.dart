import 'package:flutter/material.dart';

class AppTheme {
  // --- INSTANCIAS CONSTANTES ---
  static const shadows = _Shadows();
  static const _lightColors = AppColors(
    bg: Color(0xFFFAF8F5),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F2ED),
    primary: Color(0xFFFF8C42),
    primaryDark: Color(0xFF6B3E26),
    primaryLight: Color(0xFFFFF3EB),
    primaryBorder: Color(0xFFFFD9BE),
    accent: Color(0xFFC8CA9E),
    accentDark: Color(0xFF4A4A38),
    titleText: Color(0xFF2C1810),
    bodyText: Color(0xFF6B5B4E),
    hint: Color(0xFFAA9990),
    border: Color(0xFFE8E0D8),
    borderActive: Color(0xFFFF8C42),
    statusNormal: Color(0xFF27AE60),
    successLight: Color(0xFFEAF3DE),
    successBorder: Color(0xFFC2DFA8),
    statusCritical: Color(0xFFE74C3C),
    dangerLight: Color(0xFFFCEBEB),
    dangerBorder: Color(0xFFF5C6C6),
    statusLow: Color(0xFFF1C27D),
    brownLight: Color(0xFFD4A47A),
    brownMid: Color(0xFFA8714A),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
  );

  static const _darkColors = AppColors(
    bg: Color(0xFF121212),
    card: Color(0xFF1E1E1E),
    surface: Color(0xFF2C2C2C),
    primary: Color(0xFFFF8C42),
    primaryDark: Color(0xFFE57C3A),
    primaryLight: Color(0xFF3B2A1E),
    primaryBorder: Color(0xFF4A3222),
    accent: Color(0xFFC8CA9E),
    accentDark: Color(0xFFE0E2BE),
    titleText: Color(0xFFF5F5F5),
    bodyText: Color(0xFFCCCCCC),
    hint: Color(0xFF888888),
    border: Color(0xFF333333),
    borderActive: Color(0xFFFF8C42),
    statusNormal: Color(0xFF27AE60),
    successLight: Color(0xFF1A3B22),
    successBorder: Color(0xFF245531),
    statusCritical: Color(0xFFE74C3C),
    dangerLight: Color(0xFF4A1A1A),
    dangerBorder: Color(0xFF6B2222),
    statusLow: Color(0xFFF1C27D),
    brownLight: Color(0xFFD4A47A),
    brownMid: Color(0xFFA8714A),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
  );

  static const spacing = SpacingValues();
  static const radius = _Radius();

  // --- ACCESO CON CONTEXTO (PARA MODO OSCURO) ---
  static AppColors colorsOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkColors
        : _lightColors;
  }

  static AppFont fontOf(BuildContext context) {
    return AppFont(colors: colorsOf(context));
  }

  // Proporciona colores sin contexto (útil en builders sin BuildContext)
  static AppColors get colors => _lightColors;
  static AppFont get font => AppFont(colors: colors);

  // Helpers para el estado de stock
  static Color getStockStatusColor(BuildContext context, String? status) {
    final c = colorsOf(context);
    if (status == 'critical') return c.statusCritical;
    if (status == 'low') return c.statusLow;
    return c.statusNormal;
  }

  static String getStockStatusLabel(String? status) {
    if (status == 'critical') return 'Crítico';
    if (status == 'low') return 'Bajo';
    return 'Normal';
  }
}

class AppColors {
  final Color bg;
  final Color card;
  final Color surface;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryBorder;
  final Color accent;
  final Color accentDark;
  final Color titleText;
  final Color bodyText;
  final Color hint;
  final Color border;
  final Color borderActive;
  final Color statusNormal;
  final Color successLight;
  final Color successBorder;
  final Color statusCritical;
  final Color dangerLight;
  final Color dangerBorder;
  final Color statusLow;
  final Color brownLight;
  final Color brownMid;
  final Color white;
  final Color black;

  const AppColors({
    required this.bg,
    required this.card,
    required this.surface,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryBorder,
    required this.accent,
    required this.accentDark,
    required this.titleText,
    required this.bodyText,
    required this.hint,
    required this.border,
    required this.borderActive,
    required this.statusNormal,
    required this.successLight,
    required this.successBorder,
    required this.statusCritical,
    required this.dangerLight,
    required this.dangerBorder,
    required this.statusLow,
    required this.brownLight,
    required this.brownMid,
    required this.white,
    required this.black,
  });
}

class SpacingValues {
  const SpacingValues();
  final double xs = 4.0;
  final double sm = 8.0;
  final double md = 16.0;
  final double lg = 24.0;
  final double xl = 32.0;
  final double xxl = 48.0;
}

class _Radius {
  const _Radius();
  final double sm = 8.0;
  final double md = 12.0;
  final double lg = 16.0;
  final double xl = 24.0;
  final double full = 999.0;

  BorderRadius get brSm => BorderRadius.circular(sm);
  BorderRadius get brMd => BorderRadius.circular(md);
  BorderRadius get brLg => BorderRadius.circular(lg);
  BorderRadius get brXl => BorderRadius.circular(xl);
}

class _Shadows {
  const _Shadows();

  List<BoxShadow> get cardSm => [
    BoxShadow(
      offset: const Offset(0, 1),
      blurRadius: 3,
      color: const Color(0xFF000000).withValues(alpha: 0.06),
    ),
  ];
  List<BoxShadow> get cardMd => [
    BoxShadow(
      offset: const Offset(0, 2),
      blurRadius: 8,
      color: const Color(0xFF000000).withValues(alpha: 0.09),
    ),
  ];
}

class AppFont {
  final AppColors colors;
  AppFont({required this.colors});

  TextStyle get h1 => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: colors.titleText,
    letterSpacing: -0.5,
  );

  TextStyle get h2 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: colors.titleText,
    letterSpacing: -0.3,
  );

  TextStyle get h3 => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: colors.titleText,
  );

  TextStyle get body => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: colors.bodyText,
    height: 1.5,
  );

  TextStyle get bodySmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: colors.bodyText,
    height: 1.42,
  );

  TextStyle get hintStyle =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.hint);

  // Note: AppTheme.font.hint was used, we kept the name for retro-compatibility
  TextStyle get hint => hintStyle;

  TextStyle get button =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.white);

  TextStyle get label => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: colors.titleText,
    letterSpacing: 0.3,
  );

  TextStyle get caption =>
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: colors.hint);
}
