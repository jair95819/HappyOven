import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORES ---
  static const colors = _Colors();

  // --- ESPACIADO ---
  static const spacing = _Spacing();

  // --- RADIOS ---
  static const radius = _Radius();

  // --- FUENTES / ESTILOS DE TEXTO ---
  static final font = _Font();

  // Helpers para el estado de stock
  static Color getStockStatusColor(String? status) {
    if (status == 'critical') return colors.statusCritical;
    if (status == 'low') return colors.statusLow;
    return colors.statusNormal;
  }

  static String getStockStatusLabel(String? status) {
    if (status == 'critical') return 'Crítico';
    if (status == 'low') return 'Bajo';
    return 'Normal';
  }
}

class _Colors {
  const _Colors();

  // ── Fondos
  final bg = const Color(0xFFFAF8F5);
  final card = const Color(0xFFFFFFFF);
  final surface = const Color(0xFFF5F2ED);

  // ── Primario (naranja)
  final primary = const Color(0xFFFF8C42);
  final primaryDark = const Color(0xFF6B3E26);
  final primaryLight = const Color(0xFFFFF3EB);
  final primaryBorder = const Color(0xFFFFD9BE);

  // ── Acento (oliva para headers)
  final accent = const Color(0xFFC8CA9E);
  final accentDark = const Color(0xFF4A4A38);

  // ── Textos
  final titleText = const Color(0xFF2C1810);
  final bodyText = const Color(0xFF6B5B4E);
  final hint = const Color(0xFFAA9990);

  // ── Bordes
  final border = const Color(0xFFE8E0D8);
  final borderActive = const Color(0xFFFF8C42);

  // ── Status: Éxito
  final statusNormal = const Color(0xFF27AE60);
  final successLight = const Color(0xFFEAF3DE);
  final successBorder = const Color(0xFFC2DFA8);

  // ── Status: Peligro
  final statusCritical = const Color(0xFFE74C3C);
  final dangerLight = const Color(0xFFFCEBEB);
  final dangerBorder = const Color(0xFFF5C6C6);

  // ── Status: Warning / Bajo
  final statusLow = const Color(0xFFF1C27D);

  // ── Marrones decorativos
  final brownLight = const Color(0xFFD4A47A);
  final brownMid = const Color(0xFFA8714A);

  // ── Neutros
  final white = const Color(0xFFFFFFFF);
  final black = const Color(0xFF000000);
}

class _Spacing {
  const _Spacing();
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

class _Font {
  final h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF2C1810),
    letterSpacing: -0.5,
  );

  final h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF2C1810),
    letterSpacing: -0.3,
  );

  final h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF2C1810),
  );

  final body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B5B4E),
    height: 1.5,
  );

  final bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B5B4E),
    height: 1.42,
  );

  final hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFAA9990),
  );

  final button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  final label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF2C1810),
    letterSpacing: 0.3,
  );

  final caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFAA9990),
  );
}
