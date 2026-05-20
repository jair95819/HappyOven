import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/theme/theme.dart';

import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';

class HistorialKardexView extends ConsumerWidget {
  const HistorialKardexView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    final movimientosState = ref.watch(movimientosViewModelProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(context, colors, font, movimientosState),
          Expanded(
            child: movimientosState.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colors.statusCritical,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text('Error al cargar movimientos', style: font.label),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref
                          .read(movimientosViewModelProvider.notifier)
                          .cargarMovimientos(),
                      child: Text(
                        'Reintentar',
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              data: (movimientos) => movimientos.isEmpty
                  ? _buildVacio(colors, font)
                  : _buildLista(context, colors, font, movimientos),
            ),
          ),
        ],
      ),
      // FAB con acciones rápidas
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ocr',
            onPressed: () => context.push('/movimientos/ingreso-ocr'),
            backgroundColor: colors.primary,
            child: Icon(
              Icons.document_scanner_outlined,
              color: colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'salida',
            onPressed: () => context.push('/movimientos/salida'),
            backgroundColor: colors.titleText,
            child: Icon(Icons.add_rounded, color: colors.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppColors colors,
    AppFont font,
    AsyncValue<List<Movimiento>> state,
  ) {
    final total = state.maybeWhen(
      data: (lista) => lista.length,
      orElse: () => 0,
    );

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
                  Text(
                    'Todos los movimientos',
                    style: font.caption.copyWith(color: colors.accentDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(color: colors.primaryBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      color: colors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$total registros',
                      style: font.label.copyWith(
                        fontSize: 12,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVacio(AppColors colors, AppFont font) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded, color: colors.hint, size: 48),
          const SizedBox(height: 12),
          Text('Sin movimientos registrados', style: font.label),
          const SizedBox(height: 4),
          Text('Los ingresos y salidas aparecerán aquí', style: font.caption),
        ],
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    AppColors colors,
    AppFont font,
    List<Movimiento> movimientos,
  ) {
    // Agrupar por fecha
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

    final grupos = agrupados.entries.toList();

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
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 80),
          itemCount: grupos.length,
          itemBuilder: (context, index) {
            final grupo = grupos[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeparadorFecha(grupo.key, colors, font),
                const SizedBox(height: 10),
                ...grupo.value.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTarjeta(m, colors, font),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildSeparadorFecha(String etiqueta, AppColors colors, AppFont font) {
    return Row(
      children: [
        Expanded(child: Divider(color: colors.hint, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            etiqueta,
            style: font.caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: colors.hint, thickness: 0.5)),
      ],
    );
  }

  Widget _buildTarjeta(Movimiento m, AppColors colors, AppFont font) {
    final config = _configPorTipo(m.tipoMovimiento, colors);
    final prefijo = m.tipoMovimiento == 'entrada' ? '+' : '−';
    final horaFmt = DateFormat('h:mm a', 'es').format(m.fecha);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
                    Expanded(
                      child: Text(
                        m.proveedor ?? config.etiqueta,
                        style: font.label.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$prefijo${m.cantidad.toStringAsFixed(m.cantidad % 1 == 0 ? 0 : 1)}',
                      style: font.label.copyWith(
                        fontSize: 13,
                        color: config.colorPrincipal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${config.etiqueta}'
                      '${m.porOcr ? ' (OCR)' : ''}'
                      '${m.motivoSalida != null ? ' · ${m.motivoSalida}' : ''}',
                      style: font.caption,
                    ),
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

  _ConfigMovimiento _configPorTipo(String tipo, AppColors colors) {
    switch (tipo) {
      case 'entrada':
        return _ConfigMovimiento(
          icono: Icons.arrow_circle_down_outlined,
          colorPrincipal: colors.statusNormal,
          colorFondo: colors.successLight,
          etiqueta: 'Entrada',
        );
      case 'salida_produccion':
        return _ConfigMovimiento(
          icono: Icons.arrow_circle_up_outlined,
          colorPrincipal: colors.primary,
          colorFondo: colors.primaryLight,
          etiqueta: 'Pase a producción',
        );
      case 'merma':
        return _ConfigMovimiento(
          icono: Icons.delete_outline_rounded,
          colorPrincipal: colors.statusCritical,
          colorFondo: colors.dangerLight,
          etiqueta: 'Merma',
        );
      case 'ajuste':
        return _ConfigMovimiento(
          icono: Icons.tune_rounded,
          colorPrincipal: colors.bodyText,
          colorFondo: colors.surface,
          etiqueta: 'Ajuste',
        );
      default:
        return _ConfigMovimiento(
          icono: Icons.swap_horiz_rounded,
          colorPrincipal: colors.hint,
          colorFondo: colors.surface,
          etiqueta: tipo,
        );
    }
  }
}

class _ConfigMovimiento {
  final IconData icono;
  final Color colorPrincipal;
  final Color colorFondo;
  final String etiqueta;

  const _ConfigMovimiento({
    required this.icono,
    required this.colorPrincipal,
    required this.colorFondo,
    required this.etiqueta,
  });
}
