import 'user.dart';

class AuthResponse {
  final String token;
  final String? refreshToken;
  final User usuario;
  final bool exito;
  final String? mensaje;

  AuthResponse({
    required this.token,
    this.refreshToken,
    required this.usuario,
    required this.exito,
    this.mensaje,
  });

  AuthResponse copyWith({
    String? token,
    String? refreshToken,
    User? usuario,
    bool? exito,
    String? mensaje,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      usuario: usuario ?? this.usuario,
      exito: exito ?? this.exito,
      mensaje: mensaje ?? this.mensaje,
    );
  }
}
