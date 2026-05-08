class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});
}

class RegisterRequest {
  final String nombre;
  final String email;
  final String password;
  final String passwordConfirmacion;

  RegisterRequest({
    required this.nombre,
    required this.email,
    required this.password,
    required this.passwordConfirmacion,
  });
}

class RecuperarPasswordRequest {
  final String email;

  RecuperarPasswordRequest({required this.email});
}
