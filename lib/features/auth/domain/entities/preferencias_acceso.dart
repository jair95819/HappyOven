/// Preferencias locales que controlan cómo se reabre la sesión al iniciar
/// la app. Se conservan tras cerrar sesión.
class PreferenciasAcceso {
  /// Mantener la sesión abierta entre reinicios.
  final bool recordarme;

  /// Exigir huella / Face ID para reabrir la sesión guardada.
  /// Implica mantener la sesión aunque [recordarme] sea `false`.
  final bool biometriaHabilitada;

  /// Último correo usado, para prellenar el formulario de login.
  final String? ultimoEmail;

  const PreferenciasAcceso({
    this.recordarme = false,
    this.biometriaHabilitada = false,
    this.ultimoEmail,
  });

  /// La sesión de Supabase debe sobrevivir al reinicio de la app.
  bool get conservarSesion => recordarme || biometriaHabilitada;
}
