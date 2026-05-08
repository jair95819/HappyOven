import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Colores Happy Oven
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _brownMid = Color(0xFFA8714A);
  static const _brownLight = Color(0xFFD4A47A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);
  static const _danger = Color(0xFFA32D2D);

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
            backgroundColor: _danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _olive,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero superior (fondo oliva)
            Expanded(flex: 4, child: _buildHero()),

            // ── Formulario (tarjeta blanca)
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
      color: _olive,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo circular
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _oliveDark, width: 2),
              color: _olive,
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(
            'Happy Oven',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Panadería artesanal',
            style: TextStyle(fontSize: 13, color: _oliveDark),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresa tus credenciales para continuar',
              style: TextStyle(fontSize: 13, color: _textGray),
            ),
            const SizedBox(height: 28),

            // Campo email
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

            // Campo contraseña
            _buildLabel('Contraseña'),
            const SizedBox(height: 6),
            _buildPasswordField(authState.cargando),
            const SizedBox(height: 10),

            // Olvidé contraseña
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.go('/recuperar-password'),
                child: Text(
                  'Olvidé mi contraseña',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _orange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón iniciar sesión
            _buildPrimaryButton(
              authState,
              () async {
                final exito = await authViewModel.login(
                  _emailController.text.trim(),
                  _passwordController.text,
                );
                if (!exito && mounted) {
                  // El error se muestra por el listener
                }
              },
            ),
            const SizedBox(height: 20),

            // Nota inferior
            Text(
              'Acceso exclusivo para personal autorizado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _brownMid,
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
        color: _orangeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(fontSize: 14, color: _textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: _brownMid, size: 18),
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
        color: _orangeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _hidePassword,
        enabled: !cargando,
        style: TextStyle(fontSize: 14, color: _textDark),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: _brownMid,
            size: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _brownMid,
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

  Widget _buildPrimaryButton(
    AuthState authState,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: authState.cargando ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: authState.cargando ? Colors.grey[400] : _orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: authState.cargando
            ? SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_olive),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : const Text(
                'Iniciar sesión',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

