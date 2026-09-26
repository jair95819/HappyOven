import '../repositories/i_auth_repository.dart';
import '../entities/auth_request.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';
import '../entities/preferencias_acceso.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResponse> call(LoginRequest request) {
    return repository.login(request);
  }
}

class RegisterUseCase {
  final IAuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthResponse> call(RegisterRequest request) {
    return repository.register(request);
  }
}

class LogoutUseCase {
  final IAuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

class RecuperarPasswordUseCase {
  final IAuthRepository repository;

  RecuperarPasswordUseCase(this.repository);

  Future<bool> call(RecuperarPasswordRequest request) {
    return repository.recuperarPassword(request);
  }
}

class ResetPasswordUseCase {
  final IAuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<AuthResponse> call(String newPassword) {
    return repository.resetPassword(newPassword);
  }
}

class VerificarSesionActivaUseCase {
  final IAuthRepository repository;

  VerificarSesionActivaUseCase(this.repository);

  Future<bool> call() {
    return repository.tieneSesionActiva();
  }
}

class ObtenerUsuarioActualUseCase {
  final IAuthRepository repository;

  ObtenerUsuarioActualUseCase(this.repository);

  Future<User?> call() {
    return repository.obtenerUsuarioActual();
  }
}

class UpdateProfileUseCase {
  final IAuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<AuthResponse> call({required String nombre, String? email}) {
    return repository.updateProfile(nombre: nombre, email: email);
  }
}

class UpdatePasswordUseCase {
  final IAuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  Future<AuthResponse> call(String currentPassword, String newPassword) {
    return repository.updatePassword(currentPassword, newPassword);
  }
}

class RestaurarSesionUseCase {
  final IAuthRepository repository;

  RestaurarSesionUseCase(this.repository);

  Future<User?> call() {
    return repository.restaurarSesion();
  }
}

/// Lee y guarda las preferencias de acceso ("Recordarme", biometría,
/// último correo).
class PreferenciasAccesoUseCase {
  final IAuthRepository repository;

  PreferenciasAccesoUseCase(this.repository);

  PreferenciasAcceso obtener() => repository.obtenerPreferencias();

  Future<void> guardarRecordarme(bool value) =>
      repository.guardarRecordarme(value);

  Future<void> guardarBiometria(bool value) =>
      repository.guardarBiometriaHabilitada(value);

  Future<void> guardarUltimoEmail(String email) =>
      repository.guardarUltimoEmail(email);
}
