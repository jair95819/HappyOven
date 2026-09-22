import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio singleton que centraliza la configuración y acceso al cliente
/// de base de datos y autenticación de Supabase.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late SupabaseClient _client;

  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  /// Retorna la instancia activa del cliente de Supabase.
  SupabaseClient get client => _client;

  /// Inicializa la conexión con el proyecto de Supabase utilizando la [url]
  /// y la clave pública [anonKey]. Debe llamarse antes de cualquier otra operación.
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }

  // ── Auth: Sign In con email y password

  /// Inicia sesión de un usuario existente usando [email] y [password].
  /// Lanza una excepción si las credenciales son incorrectas.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    }
  }

  // ── Auth: Sign Up

  /// Registra una nueva cuenta de usuario en la plataforma con el [email]
  /// y [password] especificados.
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Error de registro: ${e.message}');
    }
  }

  // ── Auth: Sign Out

  /// Cierra la sesión activa del usuario actual y limpia los tokens guardados.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Error al cerrar sesión: ${e.message}');
    }
  }

  // ── Auth: Current user

  /// Devuelve la entidad [User] del usuario actualmente logueado, o null si no hay sesión.
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // ── Auth: Current session

  /// Devuelve el objeto [Session] activo (incluyendo tokens), o null si no existe.
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  // ── Auth: Reset password

  /// Envía un correo electrónico de recuperación de contraseña a la dirección especificada.
  /// El [redirectTo] debe apuntar a una URL válida en la configuración de Auth de Supabase;
  /// sin esto, Supabase usa el valor por defecto y puede redirigir a localhost:3000.
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    try {
      final finalRedirect =
          redirectTo ??
          'https://rfzsqcgiuroncdnnhpmp.supabase.co/auth/v1/callback';
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: finalRedirect,
      );
    } on AuthException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // ── Auth: Update user auth attributes

  /// Actualiza el correo electrónico del usuario actual.
  /// Devuelve `true` si Supabase requiere confirmación (envía enlace al nuevo correo).
  Future<bool> updateAuthEmail(String email) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: email),
      );
      // Supabase returns the user with the new email in `response.user` when
      // the change is immediate, OR the old email when confirmation is pending.
      // In either case, the update was accepted — we just inform the caller.
      return response.user?.email != email;
    } on AuthException catch (e) {
      throw Exception('Error al actualizar correo: ${e.message}');
    }
  }

  /// Actualiza la contraseña del usuario actual
  Future<void> updateAuthPassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw Exception('Error al actualizar contraseña: ${e.message}');
    }
  }

  // ── DB: Obtener perfil de usuario

  /// Consulta la tabla `perfiles` para obtener los datos extendidos del perfil
  /// (incluyendo el rol) usando el [userId]. Devuelve un mapa con la información
  /// o null si no existe o falla.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // ── DB: Crear/actualizar perfil

  /// Inserta o actualiza (upsert) los campos del perfil en la tabla `perfiles`
  /// para un [userId] dado, utilizando la información del mapa [data].
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('perfiles').upsert({'id': userId, ...data});
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }
}
