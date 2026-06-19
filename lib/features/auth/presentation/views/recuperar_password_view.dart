import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class RecuperarPasswordView extends ConsumerStatefulWidget {
  const RecuperarPasswordView({super.key});

  @override
  ConsumerState<RecuperarPasswordView> createState() =>
      _RecuperarPasswordViewState();
}

class _RecuperarPasswordViewState extends ConsumerState<RecuperarPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  bool _emailEnviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.error != null && !_emailEnviado) {
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
            Expanded(flex: 5, child: _buildHero(context)),
            Expanded(
              flex: 5,
              child: _buildFormCard(context, authState, authViewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
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
                borderRadius: AppTheme.radius.brSm,
                border: Border.all(color: AppTheme.colors.border, width: 0.5),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.colors.titleText,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Ícono
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.colors.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radius.xl),
              border: Border.all(color: AppTheme.colors.border, width: 0.5),
            ),
            child: Icon(
              Icons.forward_to_inbox_outlined,
              color: AppTheme.colors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),

          Text('Recuperar contraseña', style: AppTheme.font.h3),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo y te enviaremos un enlace\npara restablecer tu contraseña.',
            style: AppTheme.font.bodySmall.copyWith(height: 1.6),
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
            if (_emailEnviado)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.colors.successLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(
                    color: AppTheme.colors.successBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.colors.statusNormal,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Email enviado correctamente.\nRevisa tu bandeja de entrada.',
                        style: AppTheme.font.bodySmall.copyWith(
                          fontSize: 12,
                          color: AppTheme.colors.statusNormal,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'CORREO ELECTRÓNICO',
                style: AppTheme.font.label.copyWith(
                  fontSize: 11,
                  color: AppTheme.colors.brownMid,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.colors.primaryLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(
                    color: AppTheme.colors.border,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authState.cargando,
                  style: AppTheme.font.bodySmall.copyWith(
                    color: AppTheme.colors.titleText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'usuario@gmail.com',
                    hintStyle: AppTheme.font.hint,
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
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
              ),
              const SizedBox(height: 28),

              // Botón enviar
              GestureDetector(
                onTap: authState.cargando
                    ? null
                    : () async {
                        final exito = await authViewModel.recuperarPassword(
                          _emailController.text.trim(),
                        );
                        if (exito && mounted) {
                          setState(() => _emailEnviado = true);
                        }
                      },
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Enviar enlace',
                          textAlign: TextAlign.center,
                          style: AppTheme.font.button,
                        ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Ya recordaste tu contraseña? ',
                  style: AppTheme.font.bodySmall.copyWith(fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Inicia sesión',
                    style: AppTheme.font.label.copyWith(
                      color: AppTheme.colors.primary,
                      fontSize: 13,
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
