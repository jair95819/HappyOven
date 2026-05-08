import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance =
      LocalStorageService._internal();
  late SharedPreferences _prefs;

  LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Token
  Future<bool> saveToken(String token) async {
    return await _prefs.setString('auth_token', token);
  }

  String? getToken() {
    return _prefs.getString('auth_token');
  }

  Future<bool> removeToken() async {
    return await _prefs.remove('auth_token');
  }

  // ── Refresh Token
  Future<bool> saveRefreshToken(String refreshToken) async {
    return await _prefs.setString('refresh_token', refreshToken);
  }

  String? getRefreshToken() {
    return _prefs.getString('refresh_token');
  }

  Future<bool> removeRefreshToken() async {
    return await _prefs.remove('refresh_token');
  }

  // ── User ID
  Future<bool> saveUserId(String userId) async {
    return await _prefs.setString('user_id', userId);
  }

  String? getUserId() {
    return _prefs.getString('user_id');
  }

  Future<bool> removeUserId() async {
    return await _prefs.remove('user_id');
  }

  // ── User Email
  Future<bool> saveUserEmail(String email) async {
    return await _prefs.setString('user_email', email);
  }

  String? getUserEmail() {
    return _prefs.getString('user_email');
  }

  // ── Limpiar todo
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
