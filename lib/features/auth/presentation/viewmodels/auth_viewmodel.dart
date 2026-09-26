import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/entities/auth_request.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/core/services/biometric_service.dart';

// ── Proveedores de dependencias
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  return AuthRepository(
    supabaseService: supabaseService,
    localStorageService: localStorageService,
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final recuperarPasswordUseCaseProvider = Provider<RecuperarPasswordUseCase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return RecuperarPasswordUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdatePasswordUseCase(repository);
});

final restaurarSesionUseCaseProvider = Provider<RestaurarSesionUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RestaurarSesionUseCase(repository);
});

final preferenciasAccesoUseCaseProvider = Provider<PreferenciasAccesoUseCase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return PreferenciasAccesoUseCase(repository);
});

final obtenerUsuarioActualUseCaseProvider =
    Provider<ObtenerUsuarioActualUseCase>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return ObtenerUsuarioActualUseCase(repository);
    });

// ── Estado de autenticación
class AuthState {
  final bool cargando;
  final User? usuario;
  final String? token;
  final String? error;
  final String? mensaje;
  final bool autenticado;

  /// Indica que aún se está restaurando la sesión persistida al arrancar la app.
  /// Mientras es `true`, el router muestra un splash en lugar de decidir entre
  /// login y dashboard, evitando el parpadeo de la pantalla de login.
  final bool inicializando;

  /// Preferencia "Recordarme": mantener la sesión entre reinicios.
  final bool recordarme;

  /// El usuario activó el ingreso con huella / Face ID.
  final bool biometriaHabilitada;

  /// El dispositivo tiene biometría con huellas/rostros registrados.
  final bool biometriaDisponible;

  /// Hay una sesión guardada esperando ser desbloqueada con biometría.
  final bool sesionBloqueada;

  /// Último correo usado, para prellenar el login.
  final String? ultimoEmail;

  AuthState({
    this.cargando = false,
    this.usuario,
    this.token,
    this.error,
    this.mensaje,
    this.autenticado = false,
    this.inicializando = false,
    this.recordarme = false,
    this.biometriaHabilitada = false,
    this.biometriaDisponible = false,
    this.sesionBloqueada = false,
    this.ultimoEmail,
  });

  AuthState copyWith({
    bool? cargando,
    User? usuario,
    String? token,
    String? error,
    String? mensaje,
    bool? autenticado,
    bool? inicializando,
    bool? recordarme,
    bool? biometriaHabilitada,
    bool? biometriaDisponible,
    bool? sesionBloqueada,
    String? ultimoEmail,
    bool clearError = false,
    bool clearMensaje = false,
  }) {
    return AuthState(
      cargando: cargando ?? this.cargando,
      usuario: usuario ?? this.usuario,
      token: token ?? this.token,
      error: clearError ? null : (error ?? this.error),
      mensaje: clearMensaje ? null : (mensaje ?? this.mensaje),
      autenticado: autenticado ?? this.autenticado,
      inicializando: inicializando ?? this.inicializando,
      recordarme: recordarme ?? this.recordarme,
      biometriaHabilitada: biometriaHabilitada ?? this.biometriaHabilitada,
      biometriaDisponible: biometriaDisponible ?? this.biometriaDisponible,
      sesionBloqueada: sesionBloqueada ?? this.sesionBloqueada,
      ultimoEmail: ultimoEmail ?? this.ultimoEmail,
    );
  }

  // Limpiar errores
  AuthState limpiarError() {
    return copyWith();
  }
}

// ── ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final RecuperarPasswordUseCase _recuperarPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UpdatePasswordUseCase _updatePasswordUseCase;
  final RestaurarSesionUseCase _restaurarSesionUseCase;
  final PreferenciasAccesoUseCase _preferencias;
  final BiometricService _biometricService;

  /// Usuario de la sesión guardada, a la espera del desbloqueo biométrico.
  User? _usuarioPendiente;

  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required RecuperarPasswordUseCase recuperarPasswordUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UpdatePasswordUseCase updatePasswordUseCase,
    required RestaurarSesionUseCase restaurarSesionUseCase,
    required PreferenciasAccesoUseCase preferenciasAccesoUseCase,
    required BiometricService biometricService,
    ObtenerUsuarioActualUseCase? obtenerUsuarioActualUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _logoutUseCase = logoutUseCase,
       _recuperarPasswordUseCase = recuperarPasswordUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _updatePasswordUseCase = updatePasswordUseCase,
       _restaurarSesionUseCase = restaurarSesionUseCase,
       _preferencias = preferenciasAccesoUseCase,
       _biometricService = biometricService,
       super(AuthState(inicializando: true)) {
    _restaurarSesion();
  }

  // ── Restaurar sesión persistida
  /// Decide qué hacer con la sesión que Supabase dejó persistida:
  /// - Sin "Recordarme" ni biometría: se descarta y se pide contraseña.
  /// - Con biometría: queda bloqueada hasta que [loginBiometrico] la abra.
  /// - Solo "Recordarme": se entra directamente.
  Future<void> _restaurarSesion() async {
    final prefs = _preferencias.obtener();
    var nuevo = state.copyWith(
      recordarme: prefs.recordarme,
      biometriaHabilitada: prefs.biometriaHabilitada,
      biometriaDisponible: await _biometricService.disponible(),
      ultimoEmail: prefs.ultimoEmail,
    );

    try {
      final usuario = await _restaurarSesionUseCase();
      if (usuario != null) {
        if (!prefs.conservarSesion) {
          await _logoutUseCase();
        } else if (prefs.biometriaHabilitada) {
          _usuarioPendiente = usuario;
          nuevo = nuevo.copyWith(sesionBloqueada: true);
        } else {
          nuevo = nuevo.copyWith(usuario: usuario, autenticado: true);
        }
      }
    } catch (_) {
      // Sin red o sesión inválida: se cae al login con contraseña.
    }

    state = nuevo.copyWith(inicializando: false);
  }

  // ── Login biométrico
  /// Desbloquea con huella / Face ID la sesión guardada al arrancar.
  Future<bool> loginBiometrico() async {
    final usuario = _usuarioPendiente;
    if (!state.sesionBloqueada || usuario == null) {
      state = state.copyWith(clearError: true);
      state = state.copyWith(
        error:
            'Inicia sesión con tu contraseña para usar el ingreso con huella',
        clearMensaje: true,
      );
      return false;
    }

    final ok = await _biometricService.autenticar(
      'Confirma tu identidad para ingresar a Happy Oven',
    );
    if (!ok) return false;

    _usuarioPendiente = null;
    state = state.copyWith(
      usuario: usuario,
      autenticado: true,
      sesionBloqueada: false,
      clearError: true,
      clearMensaje: true,
    );
    return true;
  }

  // ── Activar / desactivar biometría
  Future<bool> cambiarBiometria(bool activar) async {
    if (activar) {
      if (!await _biometricService.disponible()) {
        state = state.copyWith(
          biometriaDisponible: false,
          error: 'Este dispositivo no tiene huella ni Face ID registrados',
        );
        return false;
      }
      final ok = await _biometricService.autenticar(
        'Confirma tu identidad para activar el ingreso biométrico',
      );
      if (!ok) return false;
    }

    await _preferencias.guardarBiometria(activar);
    state = state.copyWith(
      biometriaHabilitada: activar,
      biometriaDisponible: activar ? true : null,
      clearError: true,
    );
    return true;
  }

  // ── Login
  Future<bool> login(
    String email,
    String password, {
    bool recordarme = false,
  }) async {
    state = state.copyWith(cargando: true);

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _loginUseCase(request);

      if (response.exito) {
        _usuarioPendiente = null;
        await _preferencias.guardarRecordarme(recordarme);
        await _preferencias.guardarUltimoEmail(email);
        state = state.copyWith(
          usuario: response.usuario,
          token: response.token,
          autenticado: true,
          recordarme: recordarme,
          ultimoEmail: email,
          sesionBloqueada: false,
          cargando: false,
          clearError: true,
          clearMensaje: true,
        );
        return true;
      } else {
        state = state.copyWith(
          error: response.mensaje ?? 'Error desconocido',
          cargando: false,
          clearMensaje: true,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error: ${e.toString()}',
        cargando: false,
        clearMensaje: true,
      );
      return false;
    }
  }

  // ── Register
  Future<bool> register(
    String nombre,
    String email,
    String password,
    String passwordConfirmacion,
  ) async {
    state = state.copyWith(cargando: true);

    try {
      // Validaciones básicas
      if (nombre.isEmpty) {
        state = state.copyWith(
          error: 'El nombre no puede estar vacío',
          cargando: false,
        );
        return false;
      }

      if (email.isEmpty || !email.contains('@')) {
        state = state.copyWith(error: 'Email inválido', cargando: false);
        return false;
      }

      if (password.isEmpty || password.length < 6) {
        state = state.copyWith(
          error: 'La contraseña debe tener al menos 6 caracteres',
          cargando: false,
        );
        return false;
      }

      if (password != passwordConfirmacion) {
        state = state.copyWith(
          error: 'Las contraseñas no coinciden',
          cargando: false,
        );
        return false;
      }

      final request = RegisterRequest(
        nombre: nombre,
        email: email,
        password: password,
        passwordConfirmacion: passwordConfirmacion,
      );

      final response = await _registerUseCase(request);

      if (response.exito) {
        state = state.copyWith(
          usuario: response.usuario,
          token: response.token,
          autenticado: true,
          cargando: false,
        );
        return true;
      } else {
        state = state.copyWith(
          error: response.mensaje ?? 'Error en el registro',
          cargando: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}', cargando: false);
      return false;
    }
  }

  // ── Logout
  Future<void> logout() async {
    state = state.copyWith(cargando: true);

    try {
      await _logoutUseCase();
      _usuarioPendiente = null;
      // Conservar las preferencias de acceso para el próximo login.
      state = AuthState(
        recordarme: state.recordarme,
        biometriaHabilitada: state.biometriaHabilitada,
        biometriaDisponible: state.biometriaDisponible,
        ultimoEmail: state.ultimoEmail,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cerrar sesión: ${e.toString()}',
        cargando: false,
      );
    }
  }

  // ── Recuperar contraseña
  Future<bool> recuperarPassword(String email) async {
    state = state.copyWith(cargando: true);

    try {
      if (email.isEmpty || !email.contains('@')) {
        state = state.copyWith(error: 'Email inválido', cargando: false);
        return false;
      }

      final request = RecuperarPasswordRequest(email: email);
      final exito = await _recuperarPasswordUseCase(request);

      state = state.copyWith(
        cargando: false,
        error: exito ? null : 'No se pudo enviar el email de recuperación',
      );

      return exito;
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}', cargando: false);
      return false;
    }
  }

  // ── Restablecer contraseña desde el enlace de recuperación
  Future<bool> resetPassword(String newPassword) async {
    state = state.copyWith(cargando: true);

    try {
      if (newPassword.isEmpty || newPassword.length < 6) {
        state = state.copyWith(
          error: 'La contraseña debe tener al menos 6 caracteres',
          cargando: false,
        );
        return false;
      }

      final response = await _resetPasswordUseCase(newPassword);

      if (response.exito) {
        state = state.copyWith(
          cargando: false,
          clearError: true,
          clearMensaje: true,
        );
        return true;
      }

      state = state.copyWith(
        error: response.mensaje ?? 'No se pudo restablecer la contraseña',
        cargando: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}', cargando: false);
      return false;
    }
  }

  // ── Limpiar error
  void limpiarError() {
    state = state.limpiarError();
  }

  // ── Actualizar perfil
  Future<bool> updateProfile(String nombre, String email) async {
    state = state.copyWith(cargando: true);

    try {
      if (nombre.isEmpty) {
        state = state.copyWith(
          error: 'El nombre no puede estar vacío',
          cargando: false,
        );
        return false;
      }

      final response = await _updateProfileUseCase(
        nombre: nombre,
        email: email,
      );

      if (response.exito) {
        state = state.copyWith(
          usuario: response.usuario,
          mensaje: response.mensaje,
          cargando: false,
        );
        return true;
      } else {
        state = state.copyWith(
          error: response.mensaje ?? 'Error al actualizar',
          cargando: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}', cargando: false);
      return false;
    }
  }

  // ── Cambiar contraseña
  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(cargando: true);

    try {
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          newPassword.length < 6) {
        state = state.copyWith(error: 'Contraseña inválida', cargando: false);
        return false;
      }

      final response = await _updatePasswordUseCase(
        currentPassword,
        newPassword,
      );

      if (response.exito) {
        state = state.copyWith(cargando: false);
        return true;
      } else {
        state = state.copyWith(
          error: response.mensaje ?? 'Error al actualizar',
          cargando: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}', cargando: false);
      return false;
    }
  }
}

// ── Proveedor del ViewModel
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final registerUseCase = ref.watch(registerUseCaseProvider);
  final logoutUseCase = ref.watch(logoutUseCaseProvider);
  final recuperarPasswordUseCase = ref.watch(recuperarPasswordUseCaseProvider);
  final resetPasswordUseCase = ref.watch(resetPasswordUseCaseProvider);
  final updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
  final updatePasswordUseCase = ref.watch(updatePasswordUseCaseProvider);
  final restaurarSesionUseCase = ref.watch(restaurarSesionUseCaseProvider);
  final preferenciasAccesoUseCase = ref.watch(
    preferenciasAccesoUseCaseProvider,
  );
  final biometricService = ref.watch(biometricServiceProvider);

  return AuthViewModel(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
    recuperarPasswordUseCase: recuperarPasswordUseCase,
    resetPasswordUseCase: resetPasswordUseCase,
    updateProfileUseCase: updateProfileUseCase,
    updatePasswordUseCase: updatePasswordUseCase,
    restaurarSesionUseCase: restaurarSesionUseCase,
    preferenciasAccesoUseCase: preferenciasAccesoUseCase,
    biometricService: biometricService,
  );
});
