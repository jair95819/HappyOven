import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';

class BottomNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El botón de Recetas debe estar visible en la navegación para seguir el flujo
    // de operación, aunque la ruta siga restringida por rol si el usuario no es admin.
    const items = <_NavItemData>[
      _NavItemData(icono: Icons.home_rounded, etiqueta: 'Dashboard', index: 0),
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
        icono: Icons.description_outlined,
        etiqueta: 'Reportes',
        index: 3,
      ),
      _NavItemData(
        icono: Icons.person_outline_rounded,
        etiqueta: 'Configuración',
        index: 4,
      ),
    ];
    final c = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              for (final item in items) Expanded(child: _buildNavItem(c, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(AppColors c, _NavItemData item) {
    final activo = navigationShell.currentIndex == item.index;
    final color = activo ? c.primary : c.bodyText;
    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (!activo) navigationShell.goBranch(item.index);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: activo ? c.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(item.icono, color: color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                item.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
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
