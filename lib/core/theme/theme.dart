import 'package:flutter/material.dart';

class AppTheme {
  // --- INSTANCIAS CONSTANTES ---
  static const shadows = _Shadows();
  // Paleta Happy Oven — Navy (#0B2137) + Crema (#F8F6F0).
  // Fuente: prototipo de diseño (src/index.css).
  static const _lightColors = AppColors(
    bg: Color(0xFFF8F6F0),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFEDF1F7),
    primary: Color(0xFF0B2137),
    primaryDark: Color(0xFF051425),
    primaryLight: Color(0xFFE6EBF2),
    primaryBorder: Color(0xFFD3DEEA),
    accent: Color(0xFF1A385C),
    accentDark: Color(0xFF0B2137),
    titleText: Color(0xFF101C2A),
    bodyText: Color(0xFF5B6978),
    hint: Color(0xFF8A97A6),
    border: Color(0xFFE2E7EE),
    borderActive: Color(0xFF0B2137),
    statusNormal: Color(0xFF1F9D55),
    successLight: Color(0xFFE3F2E6),
    successBorder: Color(0xFFBFE3C9),
    successDeep: Color(0xFF15803D),
    statusCritical: Color(0xFFDC2626),
    dangerLight: Color(0xFFFDEAEA),
    dangerBorder: Color(0xFFF7C5C5),
    statusLow: Color(0xFFE2A008),
    brownLight: Color(0xFFD3DEEA),
    brownMid: Color(0xFF5B6978),
    khaki: Color(0xFFDBE2EA),
    khakiSoft: Color(0xFFEDF1F7),
    slate: Color(0xFFD3DEEA),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
  );

  static const _darkColors = AppColors(
    bg: Color(0xFF0A1420),
    card: Color(0xFF122033),
    surface: Color(0xFF1A2B40),
    primary: Color(0xFF5B8BC4),
    primaryDark: Color(0xFF3F6FA8),
    primaryLight: Color(0xFF1A2B40),
    primaryBorder: Color(0xFF2B4C70),
    accent: Color(0xFF7FA6D4),
    accentDark: Color(0xFFD3DEEA),
    titleText: Color(0xFFF1F4F8),
    bodyText: Color(0xFFB4C0CD),
    hint: Color(0xFF7D8B9B),
    border: Color(0xFF243650),
    borderActive: Color(0xFF5B8BC4),
    statusNormal: Color(0xFF34C274),
    successLight: Color(0xFF12301F),
    successBorder: Color(0xFF1E4D32),
    successDeep: Color(0xFF4ADE80),
    statusCritical: Color(0xFFEF4444),
    dangerLight: Color(0xFF3A1717),
    dangerBorder: Color(0xFF5E2222),
    statusLow: Color(0xFFE2A008),
    brownLight: Color(0xFF2B4C70),
    brownMid: Color(0xFFB4C0CD),
    khaki: Color(0xFF16263A),
    khakiSoft: Color(0xFF0F1B2B),
    slate: Color(0xFF2B4C70),
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

  /// Tipografía de titulares (Fraunces, serif) usada en encabezados del diseño.
  static const serifFamily = 'Fraunces';
  static const sansFamily = 'PlusJakartaSans';

  static TextStyle serif(TextStyle style) =>
      style.copyWith(fontFamily: serifFamily);

  /// ThemeData de Material con la paleta y tipografía de Happy Oven.
  static ThemeData themeData(Brightness brightness) {
    final c = brightness == Brightness.dark ? _darkColors : _lightColors;
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: sansFamily,
    );
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.white,
        secondary: c.accent,
        surface: c.card,
        error: c.statusCritical,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: c.titleText,
        displayColor: c.titleText,
      ),
      dividerColor: c.border,
      appBarTheme: AppBarTheme(
        backgroundColor: c.khaki,
        foregroundColor: c.titleText,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: serifFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: c.titleText,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.white,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

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
  final Color successDeep;
  final Color statusCritical;
  final Color dangerLight;
  final Color dangerBorder;
  final Color statusLow;
  final Color brownLight;
  final Color brownMid;
  final Color khaki;
  final Color khakiSoft;
  final Color slate;
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
    required this.successDeep,
    required this.statusCritical,
    required this.dangerLight,
    required this.dangerBorder,
    required this.statusLow,
    required this.brownLight,
    required this.brownMid,
    required this.khaki,
    required this.khakiSoft,
    required this.slate,
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

  TextStyle get h1 => AppTheme.serif(TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: colors.titleText,
    letterSpacing: -0.5,
  ));

  TextStyle get h2 => AppTheme.serif(TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: colors.titleText,
    letterSpacing: -0.3,
  ));

  TextStyle get h3 => AppTheme.serif(TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: colors.titleText,
  ));

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
    fontWeight: FontWeight.w700,
    color: colors.titleText,
    letterSpacing: 0.3,
  );

  /// Etiqueta de sección en mayúsculas (SectionLabel del diseño).
  TextStyle get section => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: colors.bodyText,
    letterSpacing: 1.1,
  );

  TextStyle get caption =>
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: colors.hint);
}
