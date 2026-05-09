import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class HistorialKardexView extends ConsumerWidget {
  const HistorialKardexView({super.key});

  Map<String, List<Movimiento>> _agruparPorFecha(List<Movimiento> movimientos) {
    final Map<String, List<Movimiento>> agrupados = {};
    for (final m in movimientos) {
      final ahora = DateTime.now();
      final ayer = ahora.subtract(const Duration(days: 1));
      String etiqueta;
      if (_mismaFecha(m.fecha, ahora)) {
        etiqueta = 'Hoy — ${DateFormat('dd MMMM yyyy', 'es').format(m.fecha)}';
      } else if (_mismaFecha(m.fecha, ayer)) {
        etiqueta = 'Ayer — ${DateFormat('dd MMMM yyyy', 'es').format(m.fecha)}';
      } else {
        etiqueta = DateFormat('dd MMMM yyyy', 'es').format(m.fecha);
      }
      agrupados.putIfAbsent(etiqueta, () => []).add(m);
    }
    return agrupados;
  }

  bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaActual = GoRouterState.of(context).uri.path;
    final movimientosState = ref.watch(movimientosViewModelProvider);
    final catalogoState = ref.watch(catalogoViewModelProvider);
    final List<Articulo> articulos = catalogoState.value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: Column(
        children: [
          movimientosState.when(
            data: (movimientos) => _buildHeader(context, movimientos.length),
            loading: () => _buildHeader(context, 0),
            error: (_, __) => _buildHeader(context, 0),
          ),
          Expanded(
            child: movimientosState.when(
              data: (movimientos) {
                if (movimientos.isEmpty) {
                  return Center(child: Text('No hay movimientos registrados', style: AppTheme.fontOf(context).hint));
                }
                final agrupados = _agruparPorFecha(movimientos);
                return _buildLista(context, agrupados, articulos);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err', style: AppTheme.fontOf(context).body)),
            ),
          ),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int cantidad) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial Kardex', style: font.h3),
                  const SizedBox(height: 2),
                  Text('Todos los movimientos',
                      style: font.caption.copyWith(color: colors.accentDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(color: colors.primaryBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: colors.primary, size: 15),
                    const SizedBox(width: 6),
                    Text('$cantidad registros',
                        style: font.label.copyWith(fontSize: 12, color: colors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista(BuildContext context, Map<String, List<Movimiento>> agrupados, List<Articulo> articulos) {
    final grupos = agrupados.entries.toList();
    final colors = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      transform: Matrix4.translationValues(0, -16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
          itemCount: grupos.length,
          itemBuilder: (context, index) {
            final grupo = grupos[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeparadorFecha(context, grupo.key),
                const SizedBox(height: 10),
                ...grupo.value.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTarjetaMovimiento(context, m, articulos),
                )),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeparadorFecha(BuildContext context, String etiqueta) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    return Row(
      children: [
        Expanded(child: Divider(color: colors.hint, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(etiqueta, style: font.caption.copyWith(fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: colors.hint, thickness: 0.5)),
      ],
    );
  }

  Widget _buildTarjetaMovimiento(BuildContext context, Movimiento m, List<Articulo> articulos) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    // Mapear string tipo a enum local para UI
    _TipoMovimiento tipoEnum = _TipoMovimiento.ajuste;
    if (m.tipoMovimiento == 'entrada' || m.tipoMovimiento == 'ingreso') tipoEnum = _TipoMovimiento.entrada;
    if (m.tipoMovimiento == 'salida_produccion' || m.tipoMovimiento == 'venta') tipoEnum = _TipoMovimiento.salidaProduccion;
    if (m.tipoMovimiento == 'merma') tipoEnum = _TipoMovimiento.merma;

    final config = _configPorTipo(context, tipoEnum);
    final prefijo = (tipoEnum == _TipoMovimiento.entrada) ? '+' : '−';
    final horaFmt = DateFormat('h:mm a', 'es').format(m.fecha);

    final articulo = articulos.firstWhere((a) => a.id == m.articuloId, orElse: () => Articulo(
      id: '0', nombre: 'Desconocido', tipo: '', unidad: 'u', stockActual: 0, stockMinimo: 0, precioUnitario: 0, activo: false, createdAt: DateTime.now(), updatedAt: DateTime.now()
    ));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: config.colorFondo,
              borderRadius: AppTheme.radius.brSm,
            ),
            child: Icon(config.icono, color: config.colorPrincipal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(articulo.nombre, style: font.label.copyWith(fontSize: 13)),
                    Text('$prefijo${m.cantidad} ${articulo.unidad}',
                        style: font.label.copyWith(fontSize: 13, color: config.colorPrincipal)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${config.etiqueta}${m.porOcr ? ' (OCR)' : ''} · ${m.observacion ?? 'Sistema'}',
                        style: font.caption),
                    Text(horaFmt, style: font.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ConfigMovimiento _configPorTipo(BuildContext context, _TipoMovimiento tipo) {
    final colors = AppTheme.colorsOf(context);
    switch (tipo) {
      case _TipoMovimiento.entrada:
        return _ConfigMovimiento(icono: Icons.arrow_circle_down_outlined,
            colorPrincipal: colors.statusNormal, colorFondo: colors.successLight, etiqueta: 'Entrada');
      case _TipoMovimiento.salidaProduccion:
        return _ConfigMovimiento(icono: Icons.arrow_circle_up_outlined,
            colorPrincipal: colors.primary, colorFondo: colors.primaryLight, etiqueta: 'Pase a producción/Venta');
      case _TipoMovimiento.merma:
        return _ConfigMovimiento(icono: Icons.delete_outline_rounded,
            colorPrincipal: colors.statusCritical, colorFondo: colors.dangerLight, etiqueta: 'Merma');
      case _TipoMovimiento.ajuste:
        return _ConfigMovimiento(icono: Icons.tune_rounded,
            colorPrincipal: colors.bodyText, colorFondo: colors.surface, etiqueta: 'Ajuste');
    }
  }
}

enum _TipoMovimiento { entrada, salidaProduccion, merma, ajuste }

class _ConfigMovimiento {
  final IconData icono; final Color colorPrincipal; final Color colorFondo; final String etiqueta;
  const _ConfigMovimiento({required this.icono, required this.colorPrincipal, required this.colorFondo, required this.etiqueta});
}
