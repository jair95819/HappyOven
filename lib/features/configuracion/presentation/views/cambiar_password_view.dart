import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class CambiarPasswordView extends ConsumerStatefulWidget {
  final bool resetFlow;

  const CambiarPasswordView({super.key, this.resetFlow = false});

  @override
  ConsumerState<CambiarPasswordView> createState() =>
      _CambiarPasswordViewState();
}

class _CambiarPasswordViewState extends ConsumerState<CambiarPasswordView> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final isResetFlow = widget.resetFlow;

    return HoLoadingOverlay(
      loading: authState.cargando,
      message: 'Actualizando contraseña...',
      child: Scaffold(
        backgroundColor: AppTheme.colorsOf(context).bg,
        appBar: HoTopBar(
          title: isResetFlow ? 'Restablecer contraseña' : 'Cambiar contraseña',
          subtitle: 'Protege el acceso a tu cuenta',
          onBack: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isResetFlow) ...[
                  _buildLabel('Contraseña actual'),
                  SizedBox(height: AppTheme.spacing.sm),
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    hidePassword: _hideCurrentPassword,
                    onVisibilityChanged: () => setState(
                      () => _hideCurrentPassword = !_hideCurrentPassword,
                    ),
                    enabled: !authState.cargando,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                ],

                _buildLabel('Nueva contraseña'),
                SizedBox(height: AppTheme.spacing.sm),
                _buildPasswordField(
                  controller: _newPasswordController,
                  hidePassword: _hideNewPassword,
                  onVisibilityChanged: () =>
                      setState(() => _hideNewPassword = !_hideNewPassword),
                  enabled: !authState.cargando,
                ),
                SizedBox(height: AppTheme.spacing.lg),

                _buildLabel('Confirmar nueva contraseña'),
                SizedBox(height: AppTheme.spacing.sm),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hidePassword: _hideConfirmPassword,
                  onVisibilityChanged: () => setState(
                    () => _hideConfirmPassword = !_hideConfirmPassword,
                  ),
                  enabled: !authState.cargando,
                ),
                SizedBox(height: AppTheme.spacing.xxl),

                _buildPrimaryButton(
                  authState,
                  isResetFlow
                      ? 'Establecer contraseña'
                      : 'Actualizar contraseña',
                  () async {
                    if (_newPasswordController.text !=
                        _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Las contraseñas no coinciden'),
                          backgroundColor: AppTheme.colors.statusCritical,
                        ),
                      );
                      return;
                    }

                    final exito = isResetFlow
                        ? await authViewModel.resetPassword(
                            _newPasswordController.text,
                          )
                        : await authViewModel.updatePassword(
                            _currentPasswordController.text,
                            _newPasswordController.text,
                          );

                    if (exito && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isResetFlow
                                ? 'Contraseña restablecida exitosamente'
                                : 'Contraseña actualizada exitosamente',
                          ),
                          backgroundColor: Colors.green.shade600,
                        ),
                      );
                      if (isResetFlow) {
                        context.go('/login');
                      } else {
                        context.pop();
                      }
                    } else if (!exito && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authState.error ?? 'Error al actualizar contraseña',
                          ),
                          backgroundColor: AppTheme.colors.statusCritical,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text.toUpperCase(), style: AppTheme.fontOf(context).section);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool hidePassword,
    required VoidCallback onVisibilityChanged,
    bool enabled = true,
  }) {
    final c = AppTheme.colorsOf(context);
    return TextField(
      controller: controller,
      obscureText: hidePassword,
      enabled: enabled,
      style: TextStyle(fontSize: 15, color: c.titleText),
      decoration: hoInputDecoration(
        context,
        hint: '••••••••',
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            hidePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: c.bodyText,
            size: 20,
          ),
          onPressed: onVisibilityChanged,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    AuthState authState,
    String label,
    VoidCallback onPressed,
  ) {
    return HoPrimaryButton(
      label: label,
      loading: authState.cargando,
      onPressed: onPressed,
    );
  }
}
