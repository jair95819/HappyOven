import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      appBar: AppBar(
        title: Text(
          isResetFlow ? 'Restablecer contraseña' : 'Cambiar contraseña',
          style: AppTheme.font.h3,
        ),
        backgroundColor: AppTheme.colors.card,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.colors.titleText,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacing.xl),
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
                isResetFlow ? 'Establecer contraseña' : 'Actualizar contraseña',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool hidePassword,
    required VoidCallback onVisibilityChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: TextField(
        controller: controller,
        obscureText: hidePassword,
        enabled: enabled,
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
              hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.colors.brownMid,
              size: 18,
            ),
            onPressed: onVisibilityChanged,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    AuthState authState,
    String label,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: authState.cargando ? null : onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
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
                label,
                textAlign: TextAlign.center,
                style: AppTheme.font.button,
              ),
      ),
    );
  }
}
