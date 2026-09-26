import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
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
      if (next.error != null &&
          previous?.error != next.error &&
          !_emailEnviado) {
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
      message: 'Enviando enlace...',
      child: Scaffold(
        backgroundColor: c.card,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HoIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go('/login'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            color: c.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Recuperar contraseña',
                        style: AppTheme.serif(
                          TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.titleText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: c.bodyText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildFormCard(context, c, authState, authViewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    AppColors c,
    AuthState authState,
    AuthViewModel authViewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_emailEnviado)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.successLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.successBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: c.statusNormal,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email enviado correctamente.\nRevisa tu bandeja de entrada.',
                      style: TextStyle(fontSize: 12, color: c.successDeep),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text('CORREO ELECTRÓNICO', style: AppTheme.fontOf(context).section),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !authState.cargando,
              style: TextStyle(fontSize: 14, color: c.titleText),
              decoration: hoInputDecoration(
                context,
                hint: 'correo@happyoven.com',
                icon: Icons.mail_outline_rounded,
              ).copyWith(fillColor: c.card),
            ),
            const SizedBox(height: 16),
            HoPrimaryButton(
              label: 'Enviar enlace',
              pill: true,
              loading: authState.cargando,
              onPressed: () async {
                final exito = await authViewModel.recuperarPassword(
                  _emailController.text.trim(),
                );
                if (exito && mounted) {
                  setState(() => _emailEnviado = true);
                }
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Recordaste tu contraseña? ',
                style: TextStyle(fontSize: 12, color: c.bodyText),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'Inicia sesión',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
