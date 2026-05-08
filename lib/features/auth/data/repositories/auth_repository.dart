import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_request.dart';
import '../../domain/entities/auth_response.dart';
import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/services/local_storage_service.dart';

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
        nombre: userProfile?['nombre'] ?? response.user!.email ?? 'Usuario',
        email: response.user!.email ?? '',
        fotoPerfil: userProfile?['foto_perfil'],
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

      // TODO: Crear registro en tabla users con nombre
      await _supabaseService.updateUserProfile(response.user!.id, {
        'nombre': request.nombre,
        'email': response.user!.email,
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
        nombre: userProfile?['nombre'] ?? user.email ?? 'Usuario',
        email: user.email ?? '',
        fotoPerfil: userProfile?['foto_perfil'],
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
}
