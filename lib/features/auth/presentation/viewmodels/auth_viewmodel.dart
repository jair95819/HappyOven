import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/entities/auth_request.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'package:happy_oven/core/providers.dart';

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

// ── Estado de autenticación
class AuthState {
  final bool cargando;
  final User? usuario;
  final String? token;
  final String? error;
  final bool autenticado;

  AuthState({
    this.cargando = false,
    this.usuario,
    this.token,
    this.error,
    this.autenticado = false,
  });

  AuthState copyWith({
    bool? cargando,
    User? usuario,
    String? token,
    String? error,
    bool? autenticado,
  }) {
    return AuthState(
      cargando: cargando ?? this.cargando,
      usuario: usuario ?? this.usuario,
      token: token ?? this.token,
      error: error ?? this.error,
      autenticado: autenticado ?? this.autenticado,
    );
  }

  // Limpiar errores
  AuthState limpiarError() {
    return copyWith(error: null);
  }
}

// ── ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final RecuperarPasswordUseCase _recuperarPasswordUseCase;

  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required RecuperarPasswordUseCase recuperarPasswordUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _logoutUseCase = logoutUseCase,
       _recuperarPasswordUseCase = recuperarPasswordUseCase,
       super(AuthState());

  // ── Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(cargando: true, error: null);

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _loginUseCase(request);

      if (response.exito) {
        state = state.copyWith(
          usuario: response.usuario,
          token: response.token,
          autenticado: true,
          cargando: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          error: response.mensaje ?? 'Error desconocido',
          cargando: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}', cargando: false);
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
    state = state.copyWith(cargando: true, error: null);

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
          error: null,
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
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cerrar sesión: ${e.toString()}',
        cargando: false,
      );
    }
  }

  // ── Recuperar contraseña
  Future<bool> recuperarPassword(String email) async {
    state = state.copyWith(cargando: true, error: null);

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

  // ── Limpiar error
  void limpiarError() {
    state = state.limpiarError();
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

  return AuthViewModel(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
    recuperarPasswordUseCase: recuperarPasswordUseCase,
  );
});
