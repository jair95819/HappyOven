import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistorialKardexView extends StatelessWidget {
  const HistorialKardexView({super.key});

  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _orangeBorde = Color(0xFFFFD9BE);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);

  // Datos de ejemplo — luego vendrán del ViewModel
  static final List<_Movimiento> _movimientos = [
    _Movimiento(
      insumo: 'Harina',
      cantidad: 50,
      unidad: 'kg',
      tipo: _TipoMovimiento.entrada,
      responsable: 'Carlos M.',
      fecha: DateTime(2026, 5, 7, 9, 14),
      porOCR: false,
    ),
    _Movimiento(
      insumo: 'Azúcar',
      cantidad: 12,
      unidad: 'kg',
      tipo: _TipoMovimiento.salidaProduccion,
      responsable: 'Ana R.',
      fecha: DateTime(2026, 5, 7, 8, 30),
      porOCR: false,
    ),
    _Movimiento(
      insumo: 'Mantequilla',
      cantidad: 3,
      unidad: 'kg',
      tipo: _TipoMovimiento.merma,
      responsable: 'Carlos M.',
      fecha: DateTime(2026, 5, 7, 7, 55),
      porOCR: false,
    ),
    _Movimiento(
      insumo: 'Levadura',
      cantidad: 10,
      unidad: 'kg',
      tipo: _TipoMovimiento.entrada,
      responsable: 'Ana R.',
      fecha: DateTime(2026, 5, 6, 16, 20),
      porOCR: true,
    ),
    _Movimiento(
      insumo: 'Aceite',
      cantidad: 2,
      unidad: 'L',
      tipo: _TipoMovimiento.ajuste,
      responsable: 'Carlos M.',
      fecha: DateTime(2026, 5, 6, 11, 0),
      porOCR: false,
    ),
  ];

  // Agrupa movimientos por fecha
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
    final agrupados = _agruparPorFecha();
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLista(agrupados)),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Header oliva
  Widget _buildHeader() {
    return Container(
      color: _olive,
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
                  Text(
                    'Historial Kardex',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Todos los movimientos',
                    style: TextStyle(fontSize: 12, color: _oliveDark),
                  ),
                ],
              ),
              // Contador total
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _orangeBorde, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      color: _orange,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_movimientos.length} registros',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _orange,
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

  // ── Lista agrupada por fecha
  Widget _buildLista(Map<String, List<_Movimiento>> agrupados) {
    final grupos = agrupados.entries.toList();
    return Container(
      decoration: const BoxDecoration(
        color: _beige,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      transform: Matrix4.translationValues(0, -16, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
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
                ...grupo.value.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTarjetaMovimiento(m),
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

  // ── Separador de fecha
  Widget _buildSeparadorFecha(String etiqueta) {
    return Row(
      children: [
        Expanded(child: Divider(color: _textMuted, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: _textMuted, thickness: 0.5)),
      ],
    );
  }

  // ── Tarjeta de movimiento
  Widget _buildTarjetaMovimiento(_Movimiento m) {
    final config = _configPorTipo(m.tipo);
    final prefijo = m.tipo == _TipoMovimiento.entrada ? '+' : '−';
    final horaFmt = DateFormat('h:mm a', 'es').format(m.fecha);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _beigeDeep, width: 0.5),
      ),
      child: Row(
        children: [
          // Ícono tipo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.colorFondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icono, color: config.colorPrincipal, size: 18),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.insumo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      '$prefijo${m.cantidad} ${m.unidad}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
                      '${config.etiqueta}${m.porOCR ? ' (OCR)' : ''} · ${m.responsable}',
                      style: TextStyle(fontSize: 11, color: _textMuted),
                    ),
                    Text(
                      horaFmt,
                      style: TextStyle(fontSize: 11, color: _textMuted),
                    ),
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
        return _ConfigMovimiento(
          icono: Icons.arrow_circle_down_outlined,
          colorPrincipal: _success,
          colorFondo: _successLight,
          etiqueta: 'Entrada',
        );
      case _TipoMovimiento.salidaProduccion:
        return _ConfigMovimiento(
          icono: Icons.arrow_circle_up_outlined,
          colorPrincipal: _orange,
          colorFondo: _orangeLight,
          etiqueta: 'Pase a producción',
        );
      case _TipoMovimiento.merma:
        return _ConfigMovimiento(
          icono: Icons.delete_outline_rounded,
          colorPrincipal: _danger,
          colorFondo: _dangerLight,
          etiqueta: 'Merma',
        );
      case _TipoMovimiento.ajuste:
        return _ConfigMovimiento(
          icono: Icons.tune_rounded,
          colorPrincipal: _textGray,
          colorFondo: _beige,
          etiqueta: 'Ajuste',
        );
    }
  }

  // ── Bottom navigation
  Widget _buildBottomNav() {
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
              _buildNavItem(Icons.bar_chart_rounded, 'Dashboard', false),
              _buildNavItem(Icons.inventory_2_outlined, 'Inventario', false),
              _buildNavItem(Icons.menu_book_outlined, 'Recetas', false),
              _buildNavItem(Icons.swap_horiz_rounded, 'Movimientos', true),
              _buildNavItem(Icons.notifications_outlined, 'Alertas', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icono, String etiqueta, bool activo) {
    return Column(
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
        const SizedBox(height: 3),
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 10,
            fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
            color: activo ? _orange : _textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Modelos locales temporales
enum _TipoMovimiento { entrada, salidaProduccion, merma, ajuste }

class _Movimiento {
  final String insumo;
  final double cantidad;
  final String unidad;
  final _TipoMovimiento tipo;
  final String responsable;
  final DateTime fecha;
  final bool porOCR;

  const _Movimiento({
    required this.insumo,
    required this.cantidad,
    required this.unidad,
    required this.tipo,
    required this.responsable,
    required this.fecha,
    required this.porOCR,
  });
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
