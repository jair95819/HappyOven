import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/theme/theme_notifier.dart';

import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class PerfilAjustesView extends ConsumerWidget {
  const PerfilAjustesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold( 
      backgroundColor: AppTheme.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [ 
                    _buildProfileHeader(ref),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          _buildStatsRow(),
                          const SizedBox(height: 28),
                          _buildSectionLabel('CUENTA'),
                          const SizedBox(height: 10),
                          _buildSettingsGroup([
                            _SettingItem(
                              icon: Icons.person_outline_rounded,
                              title: 'Editar perfil',
                              subtitle: 'Nombre, correo',
                              onTap: () {},
                            ),
                            _SettingItem(
                              icon: Icons.lock_outline_rounded,
                              title: 'Cambiar contraseña',
                              subtitle: 'Seguridad de acceso',
                              onTap: () {},
                            ),
                          ]),
                          const SizedBox(height: 22 ),
                          _buildSectionLabel('ATAJOS'),
                          const SizedBox(height: 10),
                          _buildSettingsGroup([
                            _SettingItem(
                              icon: Icons.insert_chart_outlined_rounded,
                              title: 'Reportes mensuales',
                              onTap: () => context.push('/reportes'),
                            ),
                            _SettingItem(
                              icon: Icons.receipt_long_outlined,
                              title: 'Historial Kárdex',
                              onTap: () => context.push('/movimientos'),
                            ),
                            _SettingItem(
                              icon: Icons.add_box_outlined,
                              title: 'Registrar nuevo insumo',
                              onTap: () => context.push('/catalogo/nuevo'),
                            ),
                          ]),
                          const SizedBox(height: 22),
                          _buildSectionLabel('PREFERENCIAS'),
                          const SizedBox(height: 10),
                          _buildSettingsGroup([
                            _SettingItem(
                              icon: Icons.dark_mode_outlined,
                              title: 'Modo oscuro',
                              subtitle: isDarkMode ? 'Activado' : 'Desactivado',
                              trailing: Switch.adaptive(
                                value: isDarkMode,
                                onChanged: (val) {
                                  ref.read(themeProvider.notifier).toggleTheme(val);
                                },
                                thumbColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppTheme.colors.primary;
                                  }
                                  return null;
                                }),

                                activeTrackColor: AppTheme.colors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notificaciones',
                              subtitle: 'Alertas de stock',
                              trailing: Switch.adaptive(
                                value: true,
                                onChanged: (val) {},
                                thumbColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppTheme.colors.primary;
                                  }
                                  return null;
                                }),

                                activeTrackColor: AppTheme.colors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildLogoutButton(context, ref),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Happy Oven v1.0.0',
                              style: AppTheme.font.hint.copyWith(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header con avatar y gradiente sutil
  Widget _buildProfileHeader(WidgetRef ref) {
    final usuario = ref.watch(authViewModelProvider).usuario;
    final nombre = usuario?.nombre ?? 'Usuario';
    final email = usuario?.email ?? '';
    final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : 'U';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.colors.primary,
            AppTheme.colors.primary.withValues(alpha: 0.85),
            const Color(0xFFE67635),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Avatar con borde luminoso
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: Text(
                inicial,
                style: AppTheme.font.h1.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nombre,
            style: AppTheme.font.h3.copyWith(
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTheme.font.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radius.full),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 5),
                Text(
                  usuario?.rolLabel ?? 'Operario',
                  style: AppTheme.font.label.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats rápidas
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(Icons.inventory_2_outlined, '24', 'Insumos'),
        const SizedBox(width: 10),
        _buildStatChip(Icons.menu_book_outlined, '6', 'Recetas'),
        const SizedBox(width: 10),
        _buildStatChip(Icons.swap_horiz_rounded, '148', 'Movimientos'),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius.md),
          border: Border.all(color: AppTheme.colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.colors.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.font.h3.copyWith(fontSize: 18),
            ),
            Text(
              label,
              style: AppTheme.font.hint.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section labels
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppTheme.font.label.copyWith(
          fontSize: 11,
          color: AppTheme.colors.hint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Grupo de settings con bordes suaves
  Widget _buildSettingsGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: AppTheme.colors.border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.vertical(
                    top: i == 0
                        ? Radius.circular(AppTheme.radius.lg)
                        : Radius.zero,
                    bottom: isLast
                        ? Radius.circular(AppTheme.radius.lg)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Ícono con fondo suave
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radius.md),
                          ),
                          child: Icon(
                            item.icon,
                            color: AppTheme.colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Textos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTheme.font.label.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle!,
                                  style: AppTheme.font.hint.copyWith(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Trailing (chevron o switch)
                        item.trailing ??
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.colors.hint,
                              size: 22,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 0.5,
                  color: AppTheme.colors.border,
                  indent: 70,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ── Logout
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(authViewModelProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
        borderRadius: BorderRadius.circular(AppTheme.radius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius.md),
            border: Border.all(
              color: AppTheme.colors.statusCritical.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppTheme.colors.statusCritical,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Cerrar sesión',
                style: AppTheme.font.label.copyWith(
                  color: AppTheme.colors.statusCritical,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modelo interno para items de configuración
class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
}
