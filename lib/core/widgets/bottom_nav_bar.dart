import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final String rutaActual;

  const BottomNavBar({super.key, required this.rutaActual});

  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);
  static const _textMuted = Color(0xFFBFB5A0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _beigeDeep, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        if (!activo) {
          context.go(ruta);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          activo
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: Colors.white, size: 18),
                )
              : Icon(icono, color: _textMuted, size: 24),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 10,
              fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
              color: activo ? _orange : _textMuted,
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
