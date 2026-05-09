import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class CentroAlertasView extends StatefulWidget {
  const CentroAlertasView({super.key});

  @override
  State<CentroAlertasView> createState() => _CentroAlertasViewState();
}

class _CentroAlertasViewState extends State<CentroAlertasView> {
  _FiltroAlerta _filtroActivo = _FiltroAlerta.todas;

  final List<_Alerta> _alertas = [
    _Alerta(tipo: _FiltroAlerta.stockBajo, titulo: 'Stock bajo',
        mensaje: 'Stock de harina por debajo del mínimo de seguridad (8 kg restantes).',
        tiempo: 'Hace 15 min', leida: false),
    _Alerta(tipo: _FiltroAlerta.anomalia, titulo: 'Anomalía detectada',
        mensaje: 'Merma inusual de 15 kg de azúcar registrada el día de hoy.',
        tiempo: 'Hace 1 hora', leida: false),
    _Alerta(tipo: _FiltroAlerta.ia, titulo: 'Restock sugerido IA',
        mensaje: 'Se recomienda comprar 50 kg de harina en los próximos 2 días.',
        tiempo: 'Hace 2 horas', leida: false),
    _Alerta(tipo: _FiltroAlerta.ingreso, titulo: 'Ingreso registrado',
        mensaje: 'Se ingresaron 30 kg de mantequilla al almacén. (OCR)',
        tiempo: 'Ayer, 4:30 pm', leida: true),
    _Alerta(tipo: _FiltroAlerta.stockBajo, titulo: 'Stock bajo',
        mensaje: 'Stock de levadura por debajo del mínimo (2 kg restantes).',
        tiempo: 'Ayer, 9:00 am', leida: true),
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
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLista()),
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
                      Text('Centro de alertas', style: AppTheme.font.h3),
                      const SizedBox(height: 2),
                      Text(
                        '$_noLeidas notificaciones sin leer',
                        style: AppTheme.font.caption.copyWith(
                          color: AppTheme.colors.accentDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.colors.statusCritical,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_noLeidas',
                        style: AppTheme.font.label.copyWith(
                          color: AppTheme.colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _FiltroAlerta.values.map((filtro) {
                    final activo = _filtroActivo == filtro;
                    return GestureDetector(
                      onTap: () => setState(() => _filtroActivo = filtro),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6, bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: activo ? AppTheme.colors.titleText : AppTheme.colors.accent,
                          borderRadius: BorderRadius.circular(AppTheme.radius.full),
                          border: Border.all(
                            color: activo ? AppTheme.colors.titleText : AppTheme.colors.accentDark,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          filtro.etiqueta,
                          style: AppTheme.font.caption.copyWith(
                            fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                            color: activo ? AppTheme.colors.white : AppTheme.colors.accentDark,
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

  Widget _buildLista() {
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
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
          itemCount: _alertasFiltradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildAlertaCard(_alertasFiltradas[index]),
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
          color: alerta.leida ? AppTheme.colors.card : config.colorFondo,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(
            color: alerta.leida ? AppTheme.colors.border : config.colorBorde,
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: config.colorIconoFondo,
                borderRadius: AppTheme.radius.brSm,
              ),
              child: Icon(config.icono, color: config.colorIcono, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alerta.titulo,
                        style: AppTheme.font.label.copyWith(
                          fontSize: 12, color: config.colorIcono,
                        ),
                      ),
                      if (!alerta.leida)
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: config.colorIcono, shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alerta.mensaje,
                    style: AppTheme.font.bodySmall.copyWith(
                      fontSize: 12,
                      color: alerta.leida ? AppTheme.colors.bodyText : AppTheme.colors.titleText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(alerta.tiempo, style: AppTheme.font.caption),
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
        return _ConfigAlerta(icono: Icons.warning_amber_rounded,
          colorFondo: AppTheme.colors.dangerLight, colorBorde: AppTheme.colors.dangerBorder,
          colorIcono: AppTheme.colors.statusCritical,
          colorIconoFondo: AppTheme.colors.statusCritical.withValues(alpha: 0.12));
      case _FiltroAlerta.anomalia:
        return _ConfigAlerta(icono: Icons.query_stats_rounded,
          colorFondo: AppTheme.colors.dangerLight, colorBorde: AppTheme.colors.dangerBorder,
          colorIcono: AppTheme.colors.statusCritical,
          colorIconoFondo: AppTheme.colors.statusCritical.withValues(alpha: 0.12));
      case _FiltroAlerta.ia:
        return _ConfigAlerta(icono: Icons.psychology_outlined,
          colorFondo: AppTheme.colors.primaryLight, colorBorde: AppTheme.colors.primaryBorder,
          colorIcono: AppTheme.colors.primary,
          colorIconoFondo: AppTheme.colors.primary.withValues(alpha: 0.12));
      case _FiltroAlerta.ingreso:
        return _ConfigAlerta(icono: Icons.move_to_inbox_outlined,
          colorFondo: AppTheme.colors.successLight, colorBorde: AppTheme.colors.successBorder,
          colorIcono: AppTheme.colors.statusNormal,
          colorIconoFondo: AppTheme.colors.statusNormal.withValues(alpha: 0.12));
      case _FiltroAlerta.todas:
        return _ConfigAlerta(icono: Icons.notifications_outlined,
          colorFondo: AppTheme.colors.bg, colorBorde: AppTheme.colors.border,
          colorIcono: AppTheme.colors.titleText,
          colorIconoFondo: AppTheme.colors.surface);
    }
  }
}

enum _FiltroAlerta {
  todas, stockBajo, anomalia, ia, ingreso;
  String get etiqueta {
    switch (this) {
      case _FiltroAlerta.todas: return 'Todas';
      case _FiltroAlerta.stockBajo: return 'Stock bajo';
      case _FiltroAlerta.anomalia: return 'Anomalías';
      case _FiltroAlerta.ia: return 'IA';
      case _FiltroAlerta.ingreso: return 'Ingresos';
    }
  }
}

class _Alerta {
  final _FiltroAlerta tipo;
  final String titulo;
  final String mensaje;
  final String tiempo;
  final bool leida;
  const _Alerta({required this.tipo, required this.titulo, required this.mensaje,
    required this.tiempo, required this.leida});
}

class _ConfigAlerta {
  final IconData icono;
  final Color colorFondo;
  final Color colorBorde;
  final Color colorIcono;
  final Color colorIconoFondo;
  const _ConfigAlerta({required this.icono, required this.colorFondo,
    required this.colorBorde, required this.colorIcono, required this.colorIconoFondo});
}
