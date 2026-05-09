import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';

class BottomNavBar extends StatelessWidget {
  final String rutaActual;

  const BottomNavBar({super.key, required this.rutaActual});

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
                context,
                icono: Icons.bar_chart_rounded,
                etiqueta: 'Dashboard',
                ruta: '/dashboard',
              ),
              _buildNavItem(
                context,
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Inventario',
                ruta: '/catalogo',
              ),
              _buildNavItem(
                context,
                icono: Icons.menu_book_outlined,
                etiqueta: 'Recetas',
                ruta: '/recetas',
              ),
              _buildNavItem(
                context,
                icono: Icons.swap_horiz_rounded,
                etiqueta: 'Movimientos',
                ruta: '/movimientos',
              ),
              _buildNavItem(
                context,
                icono: Icons.notifications_outlined,
                etiqueta: 'Alertas',
                ruta: '/alertas',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icono,
    required String etiqueta,
    required String ruta,
  }) {
    final activo = _esRutaActiva(ruta);
    return GestureDetector(
      onTap: () {
        if (!activo) context.go(ruta);
      },
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
    );
  }

  bool _esRutaActiva(String ruta) {
    if (ruta == '/dashboard') return rutaActual == '/dashboard';
    if (ruta == '/catalogo') return rutaActual.startsWith('/catalogo');
    if (ruta == '/recetas') return rutaActual.startsWith('/recetas');
    if (ruta == '/movimientos') return rutaActual.startsWith('/movimientos');
    if (ruta == '/alertas') return rutaActual.startsWith('/alertas');
    return false;
  }
}
