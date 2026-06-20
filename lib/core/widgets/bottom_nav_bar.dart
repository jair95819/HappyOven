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
    // El módulo de Recetas (índice 2) es exclusivo del rol Administrador.
    final esAdmin = ref.watch(authViewModelProvider).usuario?.esAdmin ?? false;

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
            children: [
              _buildNavItem(
                icono: Icons.bar_chart_rounded,
                etiqueta: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Inventario',
                index: 1,
              ),
              if (esAdmin)
                _buildNavItem(
                  icono: Icons.menu_book_outlined,
                  etiqueta: 'Recetas',
                  index: 2,
                ),
              _buildNavItem(
                icono: Icons.factory_outlined,
                etiqueta: 'Produc.',
                index: 3,
              ),
              _buildNavItem(
                icono: Icons.swap_horiz_rounded,
                etiqueta: 'Mov.',
                index: 4,
              ),
              _buildNavItem(
                icono: Icons.notifications_outlined,
                etiqueta: 'Alertas',
                index: 5,
              ),
            ],
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
                      child: Icon(icono, color: AppTheme.colors.white, size: 18),
                    )
                  : Icon(icono, color: AppTheme.colors.hint, size: 22),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                  color: activo ? AppTheme.colors.primary : AppTheme.colors.hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
