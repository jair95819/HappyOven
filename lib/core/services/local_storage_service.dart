import 'package:shared_preferences/shared_preferences.dart';

/// Servicio singleton que maneja el almacenamiento local persistente 
/// utilizando SharedPreferences. Útil para guardar tokens de sesión,
/// configuración del usuario u otros datos ligeros.
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  late SharedPreferences _prefs;

  LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  /// Inicializa la instancia de SharedPreferences. 
  /// Debe llamarse al inicio de la aplicación antes de usar otros métodos.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Token
  
  /// Guarda el token de autenticación principal del usuario.
  Future<bool> saveToken(String token) async {
    return await _prefs.setString('auth_token', token);
  }

  /// Obtiene el token de autenticación guardado, o nulo si no existe.
  String? getToken() {
    return _prefs.getString('auth_token');
  }

  /// Elimina el token de autenticación del almacenamiento local.
  Future<bool> removeToken() async {
    return await _prefs.remove('auth_token');
  }

  // ── Refresh Token
  
  /// Guarda el refresh token para poder renovar la sesión sin volver a pedir credenciales.
  Future<bool> saveRefreshToken(String refreshToken) async {
    return await _prefs.setString('refresh_token', refreshToken);
  }

  /// Obtiene el refresh token guardado, o nulo si no existe.
  String? getRefreshToken() {
    return _prefs.getString('refresh_token');
  }

  /// Elimina el refresh token del almacenamiento local.
  Future<bool> removeRefreshToken() async {
    return await _prefs.remove('refresh_token');
  }

  // ── User ID

  /// Guarda el ID único del usuario autenticado.
  Future<bool> saveUserId(String userId) async {
    return await _prefs.setString('user_id', userId);
  }

  /// Obtiene el ID del usuario actual, o nulo si no hay sesión iniciada.
  String? getUserId() {
    return _prefs.getString('user_id');
  }

  /// Elimina el ID del usuario del almacenamiento local.
  Future<bool> removeUserId() async {
    return await _prefs.remove('user_id');
  }

  // ── User Email

  /// Guarda el correo electrónico del usuario autenticado.
  Future<bool> saveUserEmail(String email) async {
    return await _prefs.setString('user_email', email);
  }

  /// Obtiene el correo electrónico del usuario guardado localmente.
  String? getUserEmail() {
    return _prefs.getString('user_email');
  }

  // ── Limpiar todo
  
  /// Borra absolutamente toda la información almacenada en SharedPreferences.
  /// Generalmente usado al cerrar sesión.
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
