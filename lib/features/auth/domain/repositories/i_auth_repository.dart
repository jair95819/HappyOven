import '../entities/user.dart';
import '../entities/auth_request.dart';
import '../entities/auth_response.dart';
import '../entities/preferencias_acceso.dart';

abstract class IAuthRepository {
  /// Login con email y password
  Future<AuthResponse> login(LoginRequest request);

  /// Registro de nuevo usuario
  Future<AuthResponse> register(RegisterRequest request);

  /// Logout del usuario actual
  Future<void> logout();

  /// Recuperar contraseña
  Future<bool> recuperarPassword(RecuperarPasswordRequest request);

  /// Restablecer la contraseña desde el enlace de recuperación.
  Future<AuthResponse> resetPassword(String newPassword);

  /// Obtener usuario actual (si existe token válido)
  Future<User?> obtenerUsuarioActual();

  /// Verificar si hay sesión activa
  Future<bool> tieneSesionActiva();

  /// Refrescar token
  Future<String?> refrescarToken(String refreshToken);

  /// Actualizar perfil
  Future<AuthResponse> updateProfile({required String nombre, String? email});

  /// Cambiar contraseña
  Future<AuthResponse> updatePassword(
    String currentPassword,
    String newPassword,
  );

  /// Recupera la sesión persistida por Supabase (renovándola si expiró) y
  /// devuelve el usuario, o null si no hay sesión válida.
  Future<User?> restaurarSesion();

  /// Preferencias de acceso locales: "Recordarme", biometría y último correo.
  PreferenciasAcceso obtenerPreferencias();
  Future<void> guardarRecordarme(bool value);
  Future<void> guardarBiometriaHabilitada(bool value);
  Future<void> guardarUltimoEmail(String email);
}
