import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class BottomNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El botón de Recetas debe estar visible en la navegación para seguir el flujo
    // de operación, aunque la ruta siga restringida por rol si el usuario no es admin.
    final items = <_NavItemData>[
      _NavItemData(icono: Icons.home_rounded, etiqueta: 'Inicio', index: 0),
      _NavItemData(
        icono: Icons.inventory_2_outlined,
        etiqueta: 'Inventario',
        index: 1,
      ),
      _NavItemData(
        icono: Icons.menu_book_outlined,
        etiqueta: 'Recetas',
        index: 2,
      ),
      _NavItemData(
        icono: Icons.bar_chart_rounded,
        etiqueta: 'Reporte',
        index: 3,
      ),
      _NavItemData(
        icono: Icons.settings_outlined,
        etiqueta: 'Configuración',
        index: 4,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        border: Border(
          top: BorderSide(color: AppTheme.colors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items
                .map(
                  (item) => _buildNavItem(
                    icono: item.icono,
                    etiqueta: item.etiqueta,
                    index: item.index,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icono,
    required String etiqueta,
    required int index,
  }) {
    final activo = navigationShell.currentIndex == index;
    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (!activo) navigationShell.goBranch(index);
        },
        borderRadius: BorderRadius.circular(AppTheme.radius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              activo
                  ? Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radius.sm),
                        boxShadow: AppTheme.shadows.cardSm,
                      ),
                      child: Icon(
                        icono,
                        color: AppTheme.colors.white,
                        size: 18,
                      ),
                    )
                  : Icon(icono, color: AppTheme.colors.hint, size: 22),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                  color: activo
                      ? AppTheme.colors.primary
                      : AppTheme.colors.hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icono;
  final String etiqueta;
  final int index;

  const _NavItemData({
    required this.icono,
    required this.etiqueta,
    required this.index,
  });
}
