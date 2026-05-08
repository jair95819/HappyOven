import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late SupabaseClient _client;

  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseClient get client => _client;

  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }

  // ── Auth: Sign In con email y password
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
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Error al cerrar sesión: ${e.message}');
    }
  }

  // ── Auth: Current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // ── Auth: Current session
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  // ── Auth: Reset password
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // ── DB: Obtener perfil de usuario
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // ── DB: Actualizar perfil
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('users').update(data).eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }
}
