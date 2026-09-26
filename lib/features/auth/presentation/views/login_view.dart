import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hidePassword = true;
  late bool _recordarme;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authViewModelProvider);
    _recordarme = authState.recordarme;
    _emailController.text = authState.ultimoEmail ?? '';

    // Sesión guardada con biometría: pedir la huella en cuanto se abre.
    if (authState.sesionBloqueada && authState.biometriaDisponible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(authViewModelProvider.notifier).loginBiometrico();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    // Observar cambios de autenticación.
    // Solo mostrar el snackbar si el error realmente cambió; así no quedan
    // mensajes viejos del flujo de recuperación de contraseña apareciendo
    // después de un login exitoso.
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.autenticado) {
        authViewModel.limpiarError();
        context.go('/dashboard');
        return;
      }

      if (next.error != null &&
          previous?.error != next.error &&
          !next.autenticado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.colors.statusCritical,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final c = AppTheme.colorsOf(context);
    return HoLoadingOverlay(
      loading: authState.cargando,
      message: 'Iniciando sesión...',
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  // Espacio vacío arriba + héroe + formulario: el héroe queda
                  // centrado en el espacio libre y el formulario abajo.
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    _buildHero(c),
                    _buildForm(context, c, authState, authViewModel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          const HoLogo(),
          const SizedBox(height: 20),
          Text(
            'Bienvenido a Happy Oven',
            textAlign: TextAlign.center,
            style: AppTheme.serif(
              TextStyle(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: c.titleText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Panadería artesanal, horneado fresco y siempre delicioso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: c.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppColors c,
    AuthState authState,
    AuthViewModel authViewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel(c, 'Correo electrónico'),
          const SizedBox(height: 6),
          _buildTextField(
            c,
            controller: _emailController,
            hint: 'correo@happyoven.com',
            keyboardType: TextInputType.emailAddress,
            enabled: !authState.cargando,
          ),
          const SizedBox(height: 16),
          _buildLabel(c, 'Contraseña'),
          const SizedBox(height: 6),
          _buildTextField(
            c,
            controller: _passwordController,
            hint: '••••••••',
            obscure: _hidePassword,
            enabled: !authState.cargando,
            suffix: IconButton(
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: c.bodyText,
                size: 20,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _recordarme,
                  onChanged: (v) => setState(() => _recordarme = v ?? false),
                  activeColor: c.primary,
                  side: BorderSide(color: c.border, width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recordarme',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.bodyText,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/recuperar-password'),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: HoPrimaryButton(
                  label: 'Iniciar sesión',
                  pill: true,
                  loading: authState.cargando,
                  onPressed: () => authViewModel.login(
                    _emailController.text.trim(),
                    _passwordController.text,
                    recordarme: _recordarme,
                  ),
                ),
              ),
              if (authState.biometriaDisponible) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Ingreso por huella dactilar',
                  child: Material(
                    color: c.accent,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: authState.cargando
                          ? null
                          : authViewModel.loginBiometrico,
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Acceso exclusivo para personal autorizado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: c.hint),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(AppColors c, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: c.titleText,
      ),
    );
  }

  Widget _buildTextField(
    AppColors c, {
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    bool obscure = false,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c.border),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        obscureText: obscure,
        style: TextStyle(fontSize: 14, color: c.titleText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: c.hint),
          suffixIcon: suffix,
          filled: true,
          fillColor: c.card,
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
