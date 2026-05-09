import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
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

    // Observar cambios de autenticación
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.autenticado) {
        context.go('/dashboard');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.colors.statusCritical,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 4, child: _buildHero()),
            Expanded(
              flex: 6,
              child: _buildFormCard(context, authState, authViewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.colors.border, width: 2),
              color: AppTheme.colors.card,
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text('Happy Oven', style: AppTheme.font.h2),
          const SizedBox(height: 4),
          Text(
            'Panadería artesanal',
            style: AppTheme.font.bodySmall.copyWith(
              color: AppTheme.colors.hint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    AuthState authState,
    AuthViewModel authViewModel,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
        border: Border(
          top: BorderSide(color: AppTheme.colors.border, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bienvenido', style: AppTheme.font.h3),
            const SizedBox(height: 4),
            Text(
              'Ingresa tus credenciales para continuar',
              style: AppTheme.font.bodySmall,
            ),
            const SizedBox(height: 28),

            _buildLabel('Correo electrónico'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hint: 'usuario@gmail.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              enabled: !authState.cargando,
            ),
            const SizedBox(height: 16),

            _buildLabel('Contraseña'),
            const SizedBox(height: 6),
            _buildPasswordField(authState.cargando),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.go('/recuperar-password'),
                child: Text(
                  'Olvidé mi contraseña',
                  style: AppTheme.font.label.copyWith(
                    color: AppTheme.colors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            _buildPrimaryButton(authState, () async {
              final exito = await authViewModel.login(
                _emailController.text.trim(),
                _passwordController.text,
              );
              if (!exito && mounted) {
                // El error se muestra por el listener
              }
            }),
            const SizedBox(height: 20),

            Text(
              'Acceso exclusivo para personal autorizado',
              textAlign: TextAlign.center,
              style: AppTheme.font.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.font.label.copyWith(
        fontSize: 11,
        color: AppTheme.colors.brownMid,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: AppTheme.font.bodySmall.copyWith(
          color: AppTheme.colors.titleText,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.font.hint,
          prefixIcon: Icon(
            icon,
            color: AppTheme.colors.brownMid,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool cargando) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _hidePassword,
        enabled: !cargando,
        style: AppTheme.font.bodySmall.copyWith(
          color: AppTheme.colors.titleText,
        ),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: AppTheme.font.hint,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.colors.brownMid,
            size: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.colors.brownMid,
              size: 18,
            ),
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(AuthState authState, VoidCallback onPressed) {
    return GestureDetector(
      onTap: authState.cargando ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: authState.cargando
              ? AppTheme.colors.hint
              : AppTheme.colors.primary,
          borderRadius: AppTheme.radius.brMd,
        ),
        child: authState.cargando
            ? const SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : Text(
                'Iniciar sesión',
                textAlign: TextAlign.center,
                style: AppTheme.font.button,
              ),
      ),
    );
  }
}
