import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_request.dart';
import '../../domain/entities/auth_response.dart';
import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/services/local_storage_service.dart';
import 'package:happy_oven/core/models/enums.dart';

class AuthRepository implements IAuthRepository {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;

  AuthRepository({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
  }) : _supabaseService = supabaseService,
       _localStorageService = localStorageService;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Llamar Supabase Auth
      final response = await _supabaseService.signInWithEmail(
        request.email,
        request.password,
      );

      if (response.user == null) {
        return AuthResponse(
          token: '',
          usuario: User(
            id: '',
            nombre: '',
            email: '',
            createdAt: DateTime.now(),
            activo: false,
          ),
          exito: false,
          mensaje: 'Email o contraseña incorrectos',
        );
      }

      // Guardar token
      final token = response.session?.accessToken ?? '';
      await _localStorageService.saveToken(token);
      await _localStorageService.saveUserId(response.user!.id);
      await _localStorageService.saveUserEmail(response.user!.email ?? '');

      // Obtener perfil del usuario desde BD
      final userProfile = await _supabaseService.getUserProfile(
        response.user!.id,
      );

      final usuario = User(
        id: response.user!.id,
        nombre:
            userProfile?['nombre_completo'] ?? response.user!.email ?? 'Usuario',
        email: response.user!.email ?? '',
        fotoPerfil: userProfile?['avatar_url'],
        rol: RolUsuario.fromDb(userProfile?['rol'] ?? 'operador'),
        createdAt: DateTime.parse(response.user!.createdAt),
        activo: true,
      );

      return AuthResponse(
        token: token,
        refreshToken: response.session?.refreshToken,
        usuario: usuario,
        exito: true,
        mensaje: 'Inicio de sesión exitoso',
      );
    } catch (e) {
      return AuthResponse(
        token: '',
        usuario: User(
          id: '',
          nombre: '',
          email: '',
          createdAt: DateTime.now(),
          activo: false,
        ),
        exito: false,
        mensaje: 'Error: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      if (request.password != request.passwordConfirmacion) {
        throw Exception('Las contraseñas no coinciden');
      }

      // Registrar en Supabase Auth
      final response = await _supabaseService.signUpWithEmail(
        request.email,
        request.password,
      );

      if (response.user == null) {
        return AuthResponse(
          token: '',
          usuario: User(
            id: '',
            nombre: '',
            email: '',
            createdAt: DateTime.now(),
            activo: false,
          ),
          exito: false,
          mensaje: 'Error al registrar usuario',
        );
      }

      // Guardar token
      final token = response.session?.accessToken ?? '';
      await _localStorageService.saveToken(token);
      await _localStorageService.saveUserId(response.user!.id);
      await _localStorageService.saveUserEmail(response.user!.email ?? '');

      // Crear el perfil asociado en la tabla `perfiles` con rol por defecto.
      await _supabaseService.updateUserProfile(response.user!.id, {
        'nombre_completo': request.nombre,
        'rol': RolUsuario.operador.dbValue,
      });

      final usuario = User(
        id: response.user!.id,
        nombre: request.nombre,
        email: response.user!.email ?? '',
        createdAt: DateTime.parse(response.user!.createdAt),
        activo: true,
      );

      return AuthResponse(
        token: token,
        refreshToken: response.session?.refreshToken,
        usuario: usuario,
        exito: true,
        mensaje: 'Registro exitoso',
      );
    } catch (e) {
      return AuthResponse(
        token: '',
        usuario: User(
          id: '',
          nombre: '',
          email: '',
          createdAt: DateTime.now(),
          activo: false,
        ),
        exito: false,
        mensaje: 'Error: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
      await _localStorageService.clearAll();
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  @override
  Future<bool> recuperarPassword(RecuperarPasswordRequest request) async {
    try {
      await _supabaseService.resetPasswordForEmail(request.email);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User?> obtenerUsuarioActual() async {
    try {
      final user = _supabaseService.getCurrentUser();
      if (user == null) return null;

      final userProfile = await _supabaseService.getUserProfile(user.id);

      return User(
        id: user.id,
        nombre: userProfile?['nombre_completo'] ?? user.email ?? 'Usuario',
        email: user.email ?? '',
        fotoPerfil: userProfile?['avatar_url'],
        rol: RolUsuario.fromDb(userProfile?['rol'] ?? 'operador'),
        createdAt: DateTime.parse(user.createdAt),
        activo: true,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> tieneSesionActiva() async {
    try {
      final session = _supabaseService.getCurrentSession();
      final token = _localStorageService.getToken();
      return session != null && token != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> refrescarToken(String refreshToken) async {
    try {
      // Supabase maneja automáticamente el refresh
      final session = _supabaseService.getCurrentSession();
      if (session != null) {
        return session.accessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthResponse> updateProfile({required String nombre, String? email}) async {
    try {
      final user = _supabaseService.getCurrentUser();
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // 1. Actualizar nombre siempre (independiente del email)
      await _supabaseService.updateUserProfile(user.id, {
        'nombre_completo': nombre,
      });

      // 2. Actualizar email si es diferente (manejo independiente)
      String? emailMessage;
      if (email != null && email.isNotEmpty && email != user.email) {
        try {
          final requiereConfirmacion = await _supabaseService.updateAuthEmail(email);
          if (requiereConfirmacion) {
            emailMessage = 'Se envió un enlace de confirmación a $email';
          }
        } catch (e) {
          // Si falla el email, el nombre ya se guardó — reportar el error del email
          emailMessage = 'Error al cambiar correo: ${e.toString()}';
        }
      }

      final updatedUser = await obtenerUsuarioActual();

      // Combinar mensajes: nombre + email
      final mensaje = emailMessage != null
          ? 'Nombre actualizado. $emailMessage'
          : 'Perfil actualizado exitosamente';

      return AuthResponse(
        token: _localStorageService.getToken() ?? '',
        usuario: updatedUser ?? User(id: user.id, nombre: nombre, email: user.email ?? '', createdAt: DateTime.now(), activo: true),
        exito: true,
        mensaje: mensaje,
      );
    } catch (e) {
      return AuthResponse(
        token: '',
        usuario: User(id: '', nombre: '', email: '', createdAt: DateTime.now(), activo: false),
        exito: false,
        mensaje: 'Error al actualizar perfil: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResponse> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _supabaseService.getCurrentUser();
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Para validar el password actual, intentamos hacer login
      await _supabaseService.signInWithEmail(user.email ?? '', currentPassword);

      // Si es exitoso, cambiamos la contraseña
      await _supabaseService.updateAuthPassword(newPassword);

      return AuthResponse(
        token: _localStorageService.getToken() ?? '',
        usuario: (await obtenerUsuarioActual()) ?? User(id: '', nombre: '', email: '', createdAt: DateTime.now(), activo: false),
        exito: true,
        mensaje: 'Contraseña actualizada exitosamente',
      );
    } catch (e) {
      return AuthResponse(
        token: '',
        usuario: User(id: '', nombre: '', email: '', createdAt: DateTime.now(), activo: false),
        exito: false,
        mensaje: 'Error al actualizar contraseña: ${e.toString()}',
      );
    }
  }
}
