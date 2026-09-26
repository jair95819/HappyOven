import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/services/biometric_service.dart';
import 'package:happy_oven/features/auth/domain/entities/auth_request.dart';
import 'package:happy_oven/features/auth/domain/entities/auth_response.dart';
import 'package:happy_oven/features/auth/domain/entities/preferencias_acceso.dart';
import 'package:happy_oven/features/auth/domain/entities/user.dart';
import 'package:happy_oven/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:happy_oven/features/auth/domain/usecases/auth_usecases.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class _FakeAuthRepository implements IAuthRepository {
  bool _shouldSucceed = false;
  User? sesionGuardada;
  PreferenciasAcceso prefs;
  int logouts = 0;

  _FakeAuthRepository({
    bool shouldSucceed = false,
    this.sesionGuardada,
    this.prefs = const PreferenciasAcceso(),
  }) : _shouldSucceed = shouldSucceed;

  @override
  Future<User?> restaurarSesion() async => sesionGuardada;

  @override
  PreferenciasAcceso obtenerPreferencias() => prefs;

  @override
  Future<void> guardarRecordarme(bool value) async {
    prefs = PreferenciasAcceso(
      recordarme: value,
      biometriaHabilitada: prefs.biometriaHabilitada,
      ultimoEmail: prefs.ultimoEmail,
    );
  }

  @override
  Future<void> guardarBiometriaHabilitada(bool value) async {
    prefs = PreferenciasAcceso(
      recordarme: prefs.recordarme,
      biometriaHabilitada: value,
      ultimoEmail: prefs.ultimoEmail,
    );
  }

  @override
  Future<void> guardarUltimoEmail(String email) async {
    prefs = PreferenciasAcceso(
      recordarme: prefs.recordarme,
      biometriaHabilitada: prefs.biometriaHabilitada,
      ultimoEmail: email,
    );
  }

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
  Future<void> logout() async {
    logouts++;
    sesionGuardada = null;
  }

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

class _FakeBiometricService extends BiometricService {
  bool hayBiometria;
  bool aceptar;
  int prompts = 0;

  _FakeBiometricService({this.hayBiometria = true, this.aceptar = true});

  @override
  Future<bool> disponible() async => hayBiometria;

  @override
  Future<bool> autenticar(String motivo) async {
    prompts++;
    return aceptar;
  }
}

AuthViewModel _crearViewModel(
  _FakeAuthRepository repo, {
  BiometricService? biometria,
}) {
  return AuthViewModel(
    loginUseCase: LoginUseCase(repo),
    registerUseCase: RegisterUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    recuperarPasswordUseCase: RecuperarPasswordUseCase(repo),
    resetPasswordUseCase: ResetPasswordUseCase(repo),
    updateProfileUseCase: UpdateProfileUseCase(repo),
    updatePasswordUseCase: UpdatePasswordUseCase(repo),
    restaurarSesionUseCase: RestaurarSesionUseCase(repo),
    preferenciasAccesoUseCase: PreferenciasAccesoUseCase(repo),
    biometricService: biometria ?? _FakeBiometricService(hayBiometria: false),
  );
}

/// Espera a que termine la restauración de sesión lanzada en el constructor.
Future<void> _esperarInicio(AuthViewModel vm) async {
  while (vm.debugState.inicializando) {
    await Future<void>.delayed(Duration.zero);
  }
}

User _usuario() => User(
  id: 'user-1',
  nombre: 'Panadera',
  email: 'panadera@demo.com',
  createdAt: DateTime(2026),
  activo: true,
);

void main() {
  test('login clears stale error after a successful login', () async {
    final repo = _FakeAuthRepository(shouldSucceed: false);
    final vm = _crearViewModel(repo);

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
    final vm = _crearViewModel(repo);

    final result = await vm.resetPassword('NuevaClave123!');

    expect(result, isTrue);
    expect(vm.debugState.error, isNull);
  });

  group('Recordarme', () {
    test('sin Recordarme descarta la sesión guardada', () async {
      final repo = _FakeAuthRepository(sesionGuardada: _usuario());
      final vm = _crearViewModel(repo);
      await _esperarInicio(vm);

      expect(vm.debugState.autenticado, isFalse);
      expect(repo.logouts, 1);
    });

    test('con Recordarme restaura la sesión sin pedir contraseña', () async {
      final repo = _FakeAuthRepository(
        sesionGuardada: _usuario(),
        prefs: const PreferenciasAcceso(recordarme: true),
      );
      final vm = _crearViewModel(repo);
      await _esperarInicio(vm);

      expect(vm.debugState.autenticado, isTrue);
      expect(vm.debugState.usuario?.id, 'user-1');
      expect(repo.logouts, 0);
    });

    test('login guarda Recordarme y el último correo', () async {
      final repo = _FakeAuthRepository(shouldSucceed: true);
      final vm = _crearViewModel(repo);
      await _esperarInicio(vm);

      await vm.login('good@demo.com', 'correct', recordarme: true);

      expect(repo.prefs.recordarme, isTrue);
      expect(repo.prefs.ultimoEmail, 'good@demo.com');
    });

    test('logout conserva las preferencias de acceso', () async {
      final repo = _FakeAuthRepository(
        shouldSucceed: true,
        prefs: const PreferenciasAcceso(
          recordarme: true,
          biometriaHabilitada: true,
          ultimoEmail: 'good@demo.com',
        ),
      );
      final vm = _crearViewModel(repo);
      await _esperarInicio(vm);

      await vm.logout();

      expect(vm.debugState.recordarme, isTrue);
      expect(vm.debugState.biometriaHabilitada, isTrue);
      expect(vm.debugState.ultimoEmail, 'good@demo.com');
    });
  });

  group('Biometría', () {
    test('con biometría la sesión queda bloqueada hasta la huella', () async {
      final repo = _FakeAuthRepository(
        sesionGuardada: _usuario(),
        prefs: const PreferenciasAcceso(biometriaHabilitada: true),
      );
      final bio = _FakeBiometricService();
      final vm = _crearViewModel(repo, biometria: bio);
      await _esperarInicio(vm);

      expect(vm.debugState.autenticado, isFalse);
      expect(vm.debugState.sesionBloqueada, isTrue);
      expect(repo.logouts, 0);

      final ok = await vm.loginBiometrico();

      expect(ok, isTrue);
      expect(bio.prompts, 1);
      expect(vm.debugState.autenticado, isTrue);
      expect(vm.debugState.usuario?.id, 'user-1');
    });

    test('huella rechazada no autentica', () async {
      final repo = _FakeAuthRepository(
        sesionGuardada: _usuario(),
        prefs: const PreferenciasAcceso(biometriaHabilitada: true),
      );
      final vm = _crearViewModel(
        repo,
        biometria: _FakeBiometricService(aceptar: false),
      );
      await _esperarInicio(vm);

      expect(await vm.loginBiometrico(), isFalse);
      expect(vm.debugState.autenticado, isFalse);
      expect(vm.debugState.sesionBloqueada, isTrue);
    });

    test('sin sesión guardada pide iniciar con contraseña', () async {
      final repo = _FakeAuthRepository(
        prefs: const PreferenciasAcceso(biometriaHabilitada: true),
      );
      final bio = _FakeBiometricService();
      final vm = _crearViewModel(repo, biometria: bio);
      await _esperarInicio(vm);

      expect(await vm.loginBiometrico(), isFalse);
      expect(bio.prompts, 0);
      expect(vm.debugState.error, contains('contraseña'));
    });

    test('activar biometría exige confirmar la huella', () async {
      final repo = _FakeAuthRepository();
      final bio = _FakeBiometricService(aceptar: false);
      final vm = _crearViewModel(repo, biometria: bio);
      await _esperarInicio(vm);

      expect(await vm.cambiarBiometria(true), isFalse);
      expect(repo.prefs.biometriaHabilitada, isFalse);

      bio.aceptar = true;
      expect(await vm.cambiarBiometria(true), isTrue);
      expect(repo.prefs.biometriaHabilitada, isTrue);
      expect(vm.debugState.biometriaHabilitada, isTrue);
    });

    test('no se puede activar sin biometría en el dispositivo', () async {
      final repo = _FakeAuthRepository();
      final vm = _crearViewModel(
        repo,
        biometria: _FakeBiometricService(hayBiometria: false),
      );
      await _esperarInicio(vm);

      expect(await vm.cambiarBiometria(true), isFalse);
      expect(repo.prefs.biometriaHabilitada, isFalse);
      expect(vm.debugState.error, isNotNull);
    });
  });
}
