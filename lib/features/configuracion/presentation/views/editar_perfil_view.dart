import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class EditarPerfilView extends ConsumerStatefulWidget {
  const EditarPerfilView({super.key});

  @override
  ConsumerState<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends ConsumerState<EditarPerfilView> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rolController = TextEditingController();
  bool _biometria = true;

  void _proximamente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(authViewModelProvider).usuario;
    _nombreController.text = usuario?.nombre ?? '';
    _emailController.text = usuario?.email ?? '';
    _rolController.text = usuario?.rolLabel ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    final c = AppTheme.colorsOf(context);
    final nombre = _nombreController.text.trim();
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: HoTopBar(
        title: 'Editar perfil',
        subtitle: 'Actualiza tus datos y credenciales',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primary,
                          border: Border.all(
                            color: c.card,
                            width: 4,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                          boxShadow: AppTheme.shadows.cardMd,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          inicial,
                          style: AppTheme.serif(
                            TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: c.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: c.primary,
                          shape: CircleBorder(
                            side: BorderSide(color: c.card, width: 2),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            // TODO: subir foto de perfil.
                            onTap: _proximamente,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 16,
                                color: c.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el ícono para cambiar foto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Nombre completo'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _nombreController,
              hint: 'Juan Pérez',
              icon: Icons.person_outline_rounded,
              enabled: !authState.cargando,
            ),
            const SizedBox(height: 14),
            _buildLabel('Correo electrónico'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hint: '',
              icon: Icons.mail_outline_rounded,
              enabled: false,
              suffix: Icon(Icons.lock_outline_rounded, color: c.hint, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Para cambiar el correo contacta al administrador',
              style: TextStyle(fontSize: 11, color: c.hint),
            ),
            const SizedBox(height: 14),
            _buildLabel('Cargo / Rol'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _rolController,
              hint: '',
              icon: Icons.shield_outlined,
              enabled: false,
            ),
            const SizedBox(height: 14),
            HoCard(
              radius: 18,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.fingerprint_rounded, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autenticación por huella',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.titleText,
                          ),
                        ),
                        Text(
                          'Inicio de sesión biométrico ágil',
                          style: TextStyle(fontSize: 11, color: c.bodyText),
                        ),
                      ],
                    ),
                  ),
                  // TODO: activar biometría real.
                  HoSwitch(
                    value: _biometria,
                    onChanged: (v) => setState(() => _biometria = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            HoPrimaryButton(
              label: 'Guardar cambios',
              icon: Icons.save_outlined,
              loading: authState.cargando,
              onPressed: () async {
                final exito = await authViewModel.updateProfile(
                  _nombreController.text.trim(),
                  '', // Email read-only, no enviar cambio
                );
                if (!context.mounted) return;
                final estado = ref.read(authViewModelProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      exito
                          ? (estado.mensaje ?? 'Perfil actualizado exitosamente')
                          : (estado.error ?? 'Error al actualizar'),
                    ),
                    backgroundColor: exito ? c.statusNormal : c.statusCritical,
                  ),
                );
                if (exito) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text.toUpperCase(), style: AppTheme.fontOf(context).section);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    Widget? suffix,
  }) {
    final c = AppTheme.colorsOf(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: enabled ? c.titleText : c.bodyText,
      ),
      decoration: hoInputDecoration(
        context,
        hint: hint,
        icon: icon,
        suffixIcon: suffix,
      ).copyWith(fillColor: enabled ? c.card : c.surface),
    );
  }
}
