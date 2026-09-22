import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/features/auth/domain/entities/auth_request.dart';
import 'package:happy_oven/features/auth/domain/entities/auth_response.dart';
import 'package:happy_oven/features/auth/domain/entities/user.dart';
import 'package:happy_oven/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:happy_oven/features/auth/domain/usecases/auth_usecases.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class _FakeAuthRepository implements IAuthRepository {
  bool _shouldSucceed = false;

  _FakeAuthRepository({bool shouldSucceed = false})
    : _shouldSucceed = shouldSucceed;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (_shouldSucceed) {
      return AuthResponse(
        token: 'token',
        usuario: User(
          id: 'user-1',
          nombre: 'Panadera',
          email: request.email,
          createdAt: DateTime.now(),
          activo: true,
        ),
        exito: true,
        mensaje: 'Inicio de sesión exitoso',
      );
    }

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

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
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
      mensaje: 'No implementado',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> recuperarPassword(RecuperarPasswordRequest request) async =>
      true;

  @override
  Future<User?> obtenerUsuarioActual() async => null;

  @override
  Future<bool> tieneSesionActiva() async => false;

  @override
  Future<String?> refrescarToken(String refreshToken) async => null;

  @override
  Future<AuthResponse> updateProfile({
    required String nombre,
    String? email,
  }) async {
    return AuthResponse(
      token: '',
      usuario: User(
        id: 'user-1',
        nombre: nombre,
        email: email ?? '',
        createdAt: DateTime.now(),
        activo: true,
      ),
      exito: true,
      mensaje: 'Perfil actualizado',
    );
  }

  @override
  Future<AuthResponse> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    return AuthResponse(
      token: '',
      usuario: User(
        id: 'user-1',
        nombre: 'Panadera',
        email: 'demo@test.com',
        createdAt: DateTime.now(),
        activo: true,
      ),
      exito: true,
      mensaje: 'Contraseña actualizada',
    );
  }

  @override
  Future<AuthResponse> resetPassword(String newPassword) async {
    return AuthResponse(
      token: '',
      usuario: User(
        id: 'user-1',
        nombre: 'Panadera',
        email: 'demo@test.com',
        createdAt: DateTime.now(),
        activo: true,
      ),
      exito: true,
      mensaje: 'Contraseña restablecida',
    );
  }
}

void main() {
  test('login clears stale error after a successful login', () async {
    final repo = _FakeAuthRepository(shouldSucceed: false);
    final vm = AuthViewModel(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      recuperarPasswordUseCase: RecuperarPasswordUseCase(repo),
      resetPasswordUseCase: ResetPasswordUseCase(repo),
      updateProfileUseCase: UpdateProfileUseCase(repo),
      updatePasswordUseCase: UpdatePasswordUseCase(repo),
    );

    final failedLogin = await vm.login('bad@demo.com', 'wrong');
    expect(failedLogin, isFalse);
    expect(vm.debugState.error, 'Email o contraseña incorrectos');

    repo._shouldSucceed = true;
    final successLogin = await vm.login('good@demo.com', 'correct');

    expect(successLogin, isTrue);
    expect(vm.debugState.error, isNull);
    expect(vm.debugState.autenticado, isTrue);
  });

  test('reset password succeeds without current password', () async {
    final repo = _FakeAuthRepository(shouldSucceed: true);
    final vm = AuthViewModel(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      recuperarPasswordUseCase: RecuperarPasswordUseCase(repo),
      resetPasswordUseCase: ResetPasswordUseCase(repo),
      updateProfileUseCase: UpdateProfileUseCase(repo),
      updatePasswordUseCase: UpdatePasswordUseCase(repo),
    );

    final result = await vm.resetPassword('NuevaClave123!');

    expect(result, isTrue);
    expect(vm.debugState.error, isNull);
  });
}
