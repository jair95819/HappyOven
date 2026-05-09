import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class HistorialKardexView extends StatelessWidget {
  const HistorialKardexView({super.key});

  static final List<_Movimiento> _movimientos = [
    _Movimiento(insumo: 'Harina', cantidad: 50, unidad: 'kg',
        tipo: _TipoMovimiento.entrada, responsable: 'Carlos M.',
        fecha: DateTime(2026, 5, 7, 9, 14), porOCR: false),
    _Movimiento(insumo: 'Azúcar', cantidad: 12, unidad: 'kg',
        tipo: _TipoMovimiento.salidaProduccion, responsable: 'Ana R.',
        fecha: DateTime(2026, 5, 7, 8, 30), porOCR: false),
    _Movimiento(insumo: 'Mantequilla', cantidad: 3, unidad: 'kg',
        tipo: _TipoMovimiento.merma, responsable: 'Carlos M.',
        fecha: DateTime(2026, 5, 7, 7, 55), porOCR: false),
    _Movimiento(insumo: 'Levadura', cantidad: 10, unidad: 'kg',
        tipo: _TipoMovimiento.entrada, responsable: 'Ana R.',
        fecha: DateTime(2026, 5, 6, 16, 20), porOCR: true),
    _Movimiento(insumo: 'Aceite', cantidad: 2, unidad: 'L',
        tipo: _TipoMovimiento.ajuste, responsable: 'Carlos M.',
        fecha: DateTime(2026, 5, 6, 11, 0), porOCR: false),
  ];

  Map<String, List<_Movimiento>> _agruparPorFecha() {
    final Map<String, List<_Movimiento>> agrupados = {};
    for (final m in _movimientos) {
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
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    final agrupados = _agruparPorFecha();
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLista(agrupados)),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.colors.accent,
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
                  Text('Historial Kardex', style: AppTheme.font.h3),
                  const SizedBox(height: 2),
                  Text('Todos los movimientos',
                      style: AppTheme.font.caption.copyWith(color: AppTheme.colors.accentDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.colors.primaryLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(color: AppTheme.colors.primaryBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: AppTheme.colors.primary, size: 15),
                    const SizedBox(width: 6),
                    Text('${_movimientos.length} registros',
                        style: AppTheme.font.label.copyWith(fontSize: 12, color: AppTheme.colors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista(Map<String, List<_Movimiento>> agrupados) {
    final grupos = agrupados.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.bg,
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
                _buildSeparadorFecha(grupo.key),
                const SizedBox(height: 10),
                ...grupo.value.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTarjetaMovimiento(m),
                )),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeparadorFecha(String etiqueta) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.colors.hint, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(etiqueta, style: AppTheme.font.caption.copyWith(fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: AppTheme.colors.hint, thickness: 0.5)),
      ],
    );
  }

  Widget _buildTarjetaMovimiento(_Movimiento m) {
    final config = _configPorTipo(m.tipo);
    final prefijo = m.tipo == _TipoMovimiento.entrada ? '+' : '−';
    final horaFmt = DateFormat('h:mm a', 'es').format(m.fecha);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
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
                    Text(m.insumo, style: AppTheme.font.label.copyWith(fontSize: 13)),
                    Text('$prefijo${m.cantidad} ${m.unidad}',
                        style: AppTheme.font.label.copyWith(fontSize: 13, color: config.colorPrincipal)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${config.etiqueta}${m.porOCR ? ' (OCR)' : ''} · ${m.responsable}',
                        style: AppTheme.font.caption),
                    Text(horaFmt, style: AppTheme.font.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ConfigMovimiento _configPorTipo(_TipoMovimiento tipo) {
    switch (tipo) {
      case _TipoMovimiento.entrada:
        return _ConfigMovimiento(icono: Icons.arrow_circle_down_outlined,
            colorPrincipal: AppTheme.colors.statusNormal, colorFondo: AppTheme.colors.successLight, etiqueta: 'Entrada');
      case _TipoMovimiento.salidaProduccion:
        return _ConfigMovimiento(icono: Icons.arrow_circle_up_outlined,
            colorPrincipal: AppTheme.colors.primary, colorFondo: AppTheme.colors.primaryLight, etiqueta: 'Pase a producción');
      case _TipoMovimiento.merma:
        return _ConfigMovimiento(icono: Icons.delete_outline_rounded,
            colorPrincipal: AppTheme.colors.statusCritical, colorFondo: AppTheme.colors.dangerLight, etiqueta: 'Merma');
      case _TipoMovimiento.ajuste:
        return _ConfigMovimiento(icono: Icons.tune_rounded,
            colorPrincipal: AppTheme.colors.bodyText, colorFondo: AppTheme.colors.surface, etiqueta: 'Ajuste');
    }
  }
}

enum _TipoMovimiento { entrada, salidaProduccion, merma, ajuste }

class _Movimiento {
  final String insumo; final double cantidad; final String unidad;
  final _TipoMovimiento tipo; final String responsable; final DateTime fecha; final bool porOCR;
  const _Movimiento({required this.insumo, required this.cantidad, required this.unidad,
    required this.tipo, required this.responsable, required this.fecha, required this.porOCR});
}

class _ConfigMovimiento {
  final IconData icono; final Color colorPrincipal; final Color colorFondo; final String etiqueta;
  const _ConfigMovimiento({required this.icono, required this.colorPrincipal, required this.colorFondo, required this.etiqueta});
}
