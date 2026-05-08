import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class CentroAlertasView extends StatefulWidget {
  const CentroAlertasView({super.key});

  @override
  State<CentroAlertasView> createState() => _CentroAlertasViewState();
}

class _CentroAlertasViewState extends State<CentroAlertasView> {
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
  static const _dangerBorde = Color(0xFFF5C6C6);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);

  // Filtro activo
  _FiltroAlerta _filtroActivo = _FiltroAlerta.todas;

  // Datos de ejemplo — luego vendrán del ViewModel
  final List<_Alerta> _alertas = [
    _Alerta(
      tipo: _FiltroAlerta.stockBajo,
      titulo: 'Stock bajo',
      mensaje:
          'Stock de harina por debajo del mínimo de seguridad (8 kg restantes).',
      tiempo: 'Hace 15 min',
      leida: false,
    ),
    _Alerta(
      tipo: _FiltroAlerta.anomalia,
      titulo: 'Anomalía detectada',
      mensaje: 'Merma inusual de 15 kg de azúcar registrada el día de hoy.',
      tiempo: 'Hace 1 hora',
      leida: false,
    ),
    _Alerta(
      tipo: _FiltroAlerta.ia,
      titulo: 'Restock sugerido IA',
      mensaje: 'Se recomienda comprar 50 kg de harina en los próximos 2 días.',
      tiempo: 'Hace 2 horas',
      leida: false,
    ),
    _Alerta(
      tipo: _FiltroAlerta.ingreso,
      titulo: 'Ingreso registrado',
      mensaje: 'Se ingresaron 30 kg de mantequilla al almacén. (OCR)',
      tiempo: 'Ayer, 4:30 pm',
      leida: true,
    ),
    _Alerta(
      tipo: _FiltroAlerta.stockBajo,
      titulo: 'Stock bajo',
      mensaje: 'Stock de levadura por debajo del mínimo (2 kg restantes).',
      tiempo: 'Ayer, 9:00 am',
      leida: true,
    ),
  ];

  List<_Alerta> get _alertasFiltradas {
    if (_filtroActivo == _FiltroAlerta.todas) return _alertas;
    return _alertas.where((a) => a.tipo == _filtroActivo).toList();
  }

  int get _noLeidas => _alertas.where((a) => !a.leida).length;

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLista()),
          BottomNavBar(rutaActual: rutaActual),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centro de alertas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_noLeidas notificaciones sin leer',
                        style: TextStyle(fontSize: 12, color: _oliveDark),
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_noLeidas',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _FiltroAlerta.values.map((filtro) {
                    final activo = _filtroActivo == filtro;
                    return GestureDetector(
                      onTap: () => setState(() => _filtroActivo = filtro),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6, bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activo ? _textDark : _olive,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: activo ? _textDark : _oliveDark,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          filtro.etiqueta,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: activo
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: activo ? Colors.white : _oliveDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lista de alertas
  Widget _buildLista() {
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
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
          itemCount: _alertasFiltradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildAlertaCard(_alertasFiltradas[index]);
          },
        ),
      ),
    );
  }

  Widget _buildAlertaCard(_Alerta alerta) {
    final config = _configPorTipo(alerta.tipo);
    return Opacity(
      opacity: alerta.leida ? 0.7 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alerta.leida ? Colors.white : config.colorFondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alerta.leida ? _beigeDeep : config.colorBorde,
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: config.colorIconoFondo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(config.icono, color: config.colorIcono, size: 18),
            ),
            const SizedBox(width: 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alerta.titulo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: config.colorIcono,
                        ),
                      ),
                      if (!alerta.leida)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: config.colorIcono,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alerta.mensaje,
                    style: TextStyle(
                      fontSize: 12,
                      color: alerta.leida ? _textGray : _textDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alerta.tiempo,
                    style: TextStyle(fontSize: 10, color: _textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ConfigAlerta _configPorTipo(_FiltroAlerta tipo) {
    switch (tipo) {
      case _FiltroAlerta.stockBajo:
        return _ConfigAlerta(
          icono: Icons.warning_amber_rounded,
          colorFondo: _dangerLight,
          colorBorde: _dangerBorde,
          colorIcono: _danger,
          colorIconoFondo: _danger.withOpacity(0.12),
        );
      case _FiltroAlerta.anomalia:
        return _ConfigAlerta(
          icono: Icons.query_stats_rounded,
          colorFondo: _dangerLight,
          colorBorde: _dangerBorde,
          colorIcono: _danger,
          colorIconoFondo: _danger.withOpacity(0.12),
        );
      case _FiltroAlerta.ia:
        return _ConfigAlerta(
          icono: Icons.psychology_outlined,
          colorFondo: _orangeLight,
          colorBorde: _orangeBorde,
          colorIcono: _orange,
          colorIconoFondo: _orange.withOpacity(0.12),
        );
      case _FiltroAlerta.ingreso:
        return _ConfigAlerta(
          icono: Icons.move_to_inbox_outlined,
          colorFondo: _successLight,
          colorBorde: const Color(0xFFC2DFA8),
          colorIcono: _success,
          colorIconoFondo: _success.withOpacity(0.12),
        );
      case _FiltroAlerta.todas:
        return _ConfigAlerta(
          icono: Icons.notifications_outlined,
          colorFondo: _beige,
          colorBorde: _beigeDeep,
          colorIcono: _textDark,
          colorIconoFondo: _beigeDeep,
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
              _buildNavItem(Icons.swap_horiz_rounded, 'Movimientos', false),
              _buildNavItem(Icons.notifications_outlined, 'Alertas', true),
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
enum _FiltroAlerta {
  todas,
  stockBajo,
  anomalia,
  ia,
  ingreso;

  String get etiqueta {
    switch (this) {
      case _FiltroAlerta.todas:
        return 'Todas';
      case _FiltroAlerta.stockBajo:
        return 'Stock bajo';
      case _FiltroAlerta.anomalia:
        return 'Anomalías';
      case _FiltroAlerta.ia:
        return 'IA';
      case _FiltroAlerta.ingreso:
        return 'Ingresos';
    }
  }
}

class _Alerta {
  final _FiltroAlerta tipo;
  final String titulo;
  final String mensaje;
  final String tiempo;
  final bool leida;

  const _Alerta({
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.tiempo,
    required this.leida,
  });
}

class _ConfigAlerta {
  final IconData icono;
  final Color colorFondo;
  final Color colorBorde;
  final Color colorIcono;
  final Color colorIconoFondo;

  const _ConfigAlerta({
    required this.icono,
    required this.colorFondo,
    required this.colorBorde,
    required this.colorIcono,
    required this.colorIconoFondo,
  });
}
