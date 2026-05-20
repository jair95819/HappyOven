import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';

class BottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: 10,
          ),
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
              _buildNavItem(
                icono: Icons.menu_book_outlined,
                etiqueta: 'Recetas',
                index: 2,
              ),
              _buildNavItem(
                icono: Icons.swap_horiz_rounded,
                etiqueta: 'Movimientos',
                index: 3,
              ),
              _buildNavItem(
                icono: Icons.notifications_outlined,
                etiqueta: 'Alertas',
                index: 4,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              activo
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radius.sm),
                      ),
                      child: Icon(icono, color: AppTheme.colors.white, size: 18),
                    )
                  : Icon(icono, color: AppTheme.colors.hint, size: 24),
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
