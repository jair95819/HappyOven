import '../entities/user.dart';
import '../entities/auth_request.dart';
import '../entities/auth_response.dart';

abstract class IAuthRepository {
  /// Login con email y password
  Future<AuthResponse> login(LoginRequest request);

  /// Registro de nuevo usuario
  Future<AuthResponse> register(RegisterRequest request);

  /// Logout del usuario actual
  Future<void> logout();

  /// Recuperar contraseña
  Future<bool> recuperarPassword(RecuperarPasswordRequest request);

  /// Obtener usuario actual (si existe token válido)
  Future<User?> obtenerUsuarioActual();

  /// Verificar si hay sesión activa
  Future<bool> tieneSesionActiva();

  /// Refrescar token
  Future<String?> refrescarToken(String refreshToken);
}
