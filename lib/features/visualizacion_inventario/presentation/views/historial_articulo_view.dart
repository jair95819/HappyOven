import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/providers.dart';

final historialArticuloProvider = FutureProvider.family<List<Movimiento>, String>((ref, articuloId) async {
  final repo = ref.watch(movimientosRepositoryProvider);
  return repo.getMovimientosPorArticulo(articuloId);
});

final articuloDetalleProvider = FutureProvider.family<Articulo?, String>((ref, id) async {
  final repo = ref.watch(articulosRepositoryProvider);
  return repo.getArticuloById(id);
});

class HistorialArticuloView extends ConsumerWidget {
  final String articuloId;

  const HistorialArticuloView({super.key, required this.articuloId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    final historialAsync = ref.watch(historialArticuloProvider(articuloId));
    final articuloAsync = ref.watch(articuloDetalleProvider(articuloId));

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.accent,
        title: articuloAsync.when(
          data: (a) => Text(a?.nombre ?? 'Historial', style: font.h3),
          loading: () => Text('Cargando...', style: font.h3),
          error: (_, _) => Text('Historial', style: font.h3),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.titleText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: historialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: font.body)),
        data: (movimientos) {
          if (movimientos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: colors.hint, size: 48),
                  const SizedBox(height: 12),
                  Text('Sin movimientos', style: font.label),
                  const SizedBox(height: 4),
                  Text('Este artículo no tiene movimientos registrados', style: font.caption),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            itemCount: movimientos.length,
            itemBuilder: (_, i) => _buildTarjeta(movimientos[i], colors, font),
          );
        },
      ),
    );
  }

  Widget _buildTarjeta(Movimiento m, AppColors colors, AppFont font) {
    final config = _configPorTipo(m.tipoMovimiento, colors);
    final prefijo = m.tipoMovimiento == TipoMovimiento.entrada ? '+' : '−';
    final fmt = DateFormat('dd MMM yyyy h:mm a', 'es');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppTheme.radius.brSm,
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
                      Text(config.etiqueta, style: font.label.copyWith(fontSize: 13)),
                      Text(
                        '$prefijo${m.cantidad.toStringAsFixed(m.cantidad % 1 == 0 ? 0 : 1)}',
                        style: font.label.copyWith(fontSize: 13, color: config.colorPrincipal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        [
                          config.etiqueta,
                          if (m.porOcr) 'OCR',
                          if (m.proveedor != null) m.proveedor,
                          if (m.motivoSalida != null) _labelMotivo(m.motivoSalida!),
                          if (m.observacion != null) m.observacion,
                        ].join(' · '),
                        style: font.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(fmt.format(m.fecha), style: font.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelMotivo(MotivoSalida motivo) {
    switch (motivo) {
      case MotivoSalida.venta:
        return 'Venta';
      case MotivoSalida.merma:
        return 'Merma';
      case MotivoSalida.degustacion:
        return 'Degustación';
      case MotivoSalida.ajuste:
        return 'Ajuste';
    }
  }

  _ConfigMov _configPorTipo(TipoMovimiento tipo, AppColors colors) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return _ConfigMov(Icons.arrow_circle_down_outlined, colors.statusNormal, colors.successLight, 'Entrada');
      case TipoMovimiento.salidaProduccion:
        return _ConfigMov(Icons.arrow_circle_up_outlined, colors.primary, colors.primaryLight, 'Salida');
      case TipoMovimiento.merma:
        return _ConfigMov(Icons.delete_outline_rounded, colors.statusCritical, colors.dangerLight, 'Merma');
      case TipoMovimiento.ajuste:
        return _ConfigMov(Icons.tune_rounded, colors.bodyText, colors.surface, 'Ajuste');

    }
  }
}

class _ConfigMov {
  final IconData icono;
  final Color colorPrincipal;
  final Color colorFondo;
  final String etiqueta;
  const _ConfigMov(this.icono, this.colorPrincipal, this.colorFondo, this.etiqueta);
}
