import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';

final _kardexArticulosProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(articulosRepositoryProvider);
  final articulos = await repo.getArticulos();
  return {for (final a in articulos) a.id: a.nombre};
});

class HistorialKardexView extends ConsumerWidget {
  const HistorialKardexView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    final movimientosState = ref.watch(movimientosViewModelProvider);
    final articulosMapAsync = ref.watch(_kardexArticulosProvider);

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
                    Icon(Icons.error_outline, color: colors.statusCritical, size: 40),
                    SizedBox(height: AppTheme.spacing.md),
                    Text('Error al cargar movimientos', style: font.label),
                    SizedBox(height: AppTheme.spacing.sm),
                    TextButton(
                      onPressed: () => ref
                          .read(movimientosViewModelProvider.notifier)
                          .cargarMovimientos(),
                      child: Text('Reintentar', style: TextStyle(color: colors.primary)),
                    ),
                  ],
                ),
              ),
              data: (movimientos) => articulosMapAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.primary),
                ),
                error: (e, _) => Center(
                  child: Text('Error al cargar artículos', style: font.label),
                ),
                data: (articulosMap) => movimientos.isEmpty
                    ? _buildVacio(colors, font)
                    : _buildLista(context, colors, font, movimientos, articulosMap),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ocr',
            onPressed: () => context.push('/movimientos/ingreso-ocr'),
            backgroundColor: colors.primary,
            child: Icon(Icons.document_scanner_outlined, color: colors.white, size: 18),
          ),
          SizedBox(height: AppTheme.spacing.sm),
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
                  SizedBox(height: AppTheme.spacing.sm),
                  Text('Todos los movimientos', style: font.caption.copyWith(color: colors.accentDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(color: colors.primaryBorder, width: 0.5),
                  boxShadow: AppTheme.shadows.cardSm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: colors.primary, size: 15),
                    SizedBox(width: AppTheme.spacing.sm),
                    Text('$total registros', style: font.label.copyWith(fontSize: 12, color: colors.primary)),
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
          SizedBox(height: AppTheme.spacing.md),
          Text('Sin movimientos registrados', style: font.label),
          SizedBox(height: AppTheme.spacing.sm),
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
    Map<String, String> articulosMap,
  ) {
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
          padding: EdgeInsets.fromLTRB(AppTheme.spacing.md, AppTheme.spacing.lg, AppTheme.spacing.md, 80),
          itemCount: grupos.length,
          itemBuilder: (context, index) {
            final grupo = grupos[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeparadorFecha(grupo.key, colors, font),
                SizedBox(height: AppTheme.spacing.sm),
                ...grupo.value.map(
                  (m) => Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                    child: _buildTarjeta(m, colors, font, articulosMap),
                  ),
                ),
                SizedBox(height: AppTheme.spacing.sm),
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
          child: Text(etiqueta, style: font.caption.copyWith(fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: colors.hint, thickness: 0.5)),
      ],
    );
  }

  Widget _buildTarjeta(Movimiento m, AppColors colors, AppFont font, Map<String, String> articulosMap) {
    final config = _configPorTipo(m.tipoMovimiento, colors);
    final nombreArticulo = articulosMap[m.articuloId] ?? 'Artículo #${m.articuloId.substring(0, 8)}...';
    final horaFmt = DateFormat('h:mm a', 'es').format(m.fecha);

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: AppTheme.shadows.cardSm,
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
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nombreArticulo,
                        style: font.label.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${m.tipoMovimiento == TipoMovimiento.entrada ? '+' : '−'}${m.cantidad.toStringAsFixed(m.cantidad % 1 == 0 ? 0 : 1)}',
                      style: font.label.copyWith(fontSize: 13, color: config.colorPrincipal),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${config.etiqueta}'
                        '${m.porOcr ? ' (OCR)' : ''}'
                        '${m.proveedor != null ? ' · ${m.proveedor}' : ''}'
                        '${m.motivoSalida != null ? ' · ${_labelMotivo(m.motivoSalida!)}' : ''}',
                        style: font.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  _ConfigMovimiento _configPorTipo(TipoMovimiento tipo, AppColors colors) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return _ConfigMovimiento(
          icono: Icons.arrow_circle_down_outlined,
          colorPrincipal: colors.statusNormal,
          colorFondo: colors.successLight,
          etiqueta: 'Entrada',
        );
      case TipoMovimiento.salidaProduccion:
        return _ConfigMovimiento(
          icono: Icons.arrow_circle_up_outlined,
          colorPrincipal: colors.primary,
          colorFondo: colors.primaryLight,
          etiqueta: 'Pase a producción',
        );
      case TipoMovimiento.merma:
        return _ConfigMovimiento(
          icono: Icons.delete_outline_rounded,
          colorPrincipal: colors.statusCritical,
          colorFondo: colors.dangerLight,
          etiqueta: 'Merma',
        );
      case TipoMovimiento.ajuste:
        return _ConfigMovimiento(
          icono: Icons.tune_rounded,
          colorPrincipal: colors.bodyText,
          colorFondo: colors.surface,
          etiqueta: 'Ajuste',
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
