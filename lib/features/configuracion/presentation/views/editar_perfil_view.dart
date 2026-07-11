import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class EditarPerfilView extends ConsumerStatefulWidget {
  const EditarPerfilView({super.key});

  @override
  ConsumerState<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends ConsumerState<EditarPerfilView> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(authViewModelProvider).usuario;
    _nombreController.text = usuario?.nombre ?? '';
    _emailController.text = usuario?.email ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      appBar: AppBar(
        title: Text('Editar perfil', style: AppTheme.font.h3),
        backgroundColor: AppTheme.colors.card,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.colors.titleText),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('Nombre completo'),
              SizedBox(height: AppTheme.spacing.sm),
              _buildTextField(
                controller: _nombreController,
                hint: 'Juan Pérez',
                icon: Icons.person_outline_rounded,
                enabled: !authState.cargando,
              ),
              SizedBox(height: AppTheme.spacing.lg),

              _buildLabel('Correo electrónico'),
              SizedBox(height: AppTheme.spacing.sm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.md,
                  vertical: AppTheme.spacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colors.surface,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(color: AppTheme.colors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: AppTheme.colors.hint, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _emailController.text,
                        style: AppTheme.font.bodySmall.copyWith(
                          color: AppTheme.colors.hint,
                        ),
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded, color: AppTheme.colors.hint, size: 14),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Para cambiar el correo contacta al administrador',
                style: AppTheme.font.caption.copyWith(
                  fontSize: 11,
                  color: AppTheme.colors.hint,
                ),
              ),
              SizedBox(height: AppTheme.spacing.xxl),

              _buildPrimaryButton(authState, () async {
                final exito = await authViewModel.updateProfile(
                  _nombreController.text.trim(),
                  '', // Email read-only, no enviar cambio
                );
                if (exito && mounted) {
                  final msg = authState.mensaje ?? 'Perfil actualizado exitosamente';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.green.shade600,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  context.pop();
                } else if (!exito && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authState.error ?? 'Error al actualizar'),
                      backgroundColor: AppTheme.colors.statusCritical,
                    ),
                  );
                }
              }),
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
        boxShadow: AppTheme.shadows.cardSm,
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(AuthState authState, VoidCallback onPressed) {
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
                'Guardar cambios',
                textAlign: TextAlign.center,
                style: AppTheme.font.button,
              ),
      ),
    );
  }
}
