import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/theme/theme_notifier.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';

import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/alertas_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class PerfilAjustesView extends ConsumerWidget {
  const PerfilAjustesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.colorsOf(context);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final usuario = ref.watch(authViewModelProvider).usuario;
    final esAdmin = usuario?.esAdmin ?? false;
    final noLeidas =
        ref
            .watch(alertasViewModelProvider)
            .valueOrNull
            ?.where((a) => !a.leida)
            .length ??
        0;

    return HoLoadingOverlay(
      loading: ref.watch(authViewModelProvider).cargando,
      message: 'Cerrando sesión...',
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: AppTheme.serif(
                          TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: c.titleText,
                          ),
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        HoIconButton(
                          icon: Icons.notifications_none_rounded,
                          round: true,
                          tooltip: 'Alertas',
                          onTap: () => context.go('/alertas'),
                        ),
                        if (noLeidas > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: c.statusCritical,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                noLeidas > 9 ? '9+' : '$noLeidas',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildProfileCard(context, ref),
              const SizedBox(height: 16),
              const HoSectionLabel('Preferencias del sistema'),
              const SizedBox(height: 8),
              _buildSettingsGroup(context, [
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Alertas y recordatorios de vencimiento',
                  // TODO: preferencia real de notificaciones.
                  trailing: HoSwitch(value: true, onChanged: (_) {}),
                ),
                _SettingItem(
                  icon: Icons.settings_outlined,
                  title: 'Tema de la aplicación',
                  subtitle: isDarkMode ? 'Oscuro' : 'Claro (Panadería Warm)',
                  onTap: () =>
                      ref.read(themeProvider.notifier).toggleTheme(!isDarkMode),
                ),
                _SettingItem(
                  icon: Icons.language_rounded,
                  title: 'Idioma',
                  subtitle: 'Español (Perú)',
                  onTap: () => _proximamente(context),
                ),
                _SettingItem(
                  icon: Icons.shield_outlined,
                  title: 'Seguridad & Biometría',
                  subtitle: 'Contraseña y huella dactilar',
                  onTap: () => context.push('/perfil/password'),
                ),
                _SettingItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacidad',
                  subtitle: 'Gestionar datos y copia de seguridad',
                  onTap: () => _proximamente(context),
                ),
              ]),
              const SizedBox(height: 16),
              const HoSectionLabel('Atajos'),
              const SizedBox(height: 8),
              _buildSettingsGroup(context, [
                _SettingItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Historial Kárdex',
                  subtitle: 'Todos los movimientos de almacén',
                  onTap: () => context.push('/movimientos'),
                ),
                if (esAdmin)
                  _SettingItem(
                    icon: Icons.folder_outlined,
                    title: 'Categorías',
                    subtitle: 'Organiza insumos y productos',
                    onTap: () => context.push('/categorias'),
                  ),
              ]),
              const SizedBox(height: 20),
              _buildLogoutButton(context, ref),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Happy Oven v1.0.0',
                  style: TextStyle(fontSize: 12, color: c.hint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proximamente(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Próximamente')));
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref) {
    final c = AppTheme.colorsOf(context);
    final usuario = ref.watch(authViewModelProvider).usuario;
    final nombre = usuario?.nombre ?? 'Usuario';
    final email = usuario?.email ?? '';
    final inicial = nombre.trim().isNotEmpty
        ? nombre.trim()[0].toUpperCase()
        : 'U';

    return HoCard(
      radius: 22,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary,
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.2),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  inicial,
                  style: AppTheme.serif(
                    TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: c.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.titleText,
                      ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.bodyText),
                    ),
                    const SizedBox(height: 4),
                    HoBadge(
                      text: usuario?.rolLabel ?? 'Operario',
                      color: c.statusNormal,
                      background: c.statusNormal.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: c.bg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/perfil/editar'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: c.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Editar perfil',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.titleText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<_SettingItem> items) {
    final c = AppTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: items[i].onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(items[i].icon, color: c.bodyText, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.titleText,
                              ),
                            ),
                            if (items[i].subtitle != null)
                              Text(
                                items[i].subtitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.bodyText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      items[i].trailing ??
                          Icon(
                            Icons.chevron_right_rounded,
                            color: c.bodyText,
                            size: 18,
                          ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final c = AppTheme.colorsOf(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () async {
          await ref.read(authViewModelProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.statusCritical.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: c.statusCritical, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.statusCritical,
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
