import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecuperarPasswordView extends StatefulWidget {
  const RecuperarPasswordView({super.key});

  @override
  State<RecuperarPasswordView> createState() => _RecuperarPasswordViewState();
}

class _RecuperarPasswordViewState extends State<RecuperarPasswordView> {
  final TextEditingController _emailController = TextEditingController();

  static const _beige = Color(0xFFF5F0E8);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _brownMid = Color(0xFFA8714A);
  static const _brownLight = Color(0xFFD4A47A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beige,
      body: SafeArea(
        child: Column(
          children: [
            // ── Zona superior (beige)
            Expanded(flex: 5, child: _buildHero(context)),

            // ── Formulario (tarjeta blanca)
            Expanded(flex: 5, child: _buildFormCard(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      color: _beige,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón atrás
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _textMuted, width: 0.5),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _textDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Ícono ilustrativo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _orangeLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _brownLight, width: 0.5),
            ),
            child: const Icon(
              Icons.forward_to_inbox_outlined,
              color: _orange,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Recuperar contraseña',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo y te enviaremos un enlace\npara restablecer tu contraseña.',
            style: TextStyle(fontSize: 13, color: _textGray, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
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
            // Label
            Text(
              'CORREO ELECTRÓNICO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _brownMid,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),

            // Campo email
            Container(
              decoration: BoxDecoration(
                color: _orangeLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _brownLight, width: 0.5),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 14, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'usuario@gmail.com',
                  hintStyle: TextStyle(color: _textMuted, fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: _brownMid,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Botón enviar
            GestureDetector(
              onTap: () {
                // TODO: conectar con AuthViewModel → resetPassword()
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Enviar enlace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Volver al login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Ya recordaste tu contraseña? ',
                  style: TextStyle(fontSize: 13, color: _textGray),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Inicia sesión',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
