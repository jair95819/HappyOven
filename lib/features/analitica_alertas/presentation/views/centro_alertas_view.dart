import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
import 'package:happy_oven/core/models/alerta.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/alertas_viewmodel.dart';
import 'package:intl/intl.dart';

class CentroAlertasView extends ConsumerStatefulWidget {
  const CentroAlertasView({super.key});

  @override
  ConsumerState<CentroAlertasView> createState() => _CentroAlertasViewState();
}

class _CentroAlertasViewState extends ConsumerState<CentroAlertasView> {
  String _filtroActivo = 'todas';

  final Map<String, String> _filtros = {
    'todas': 'Todas',
    'stock_bajo': 'Stock bajo',
    'anomalia': 'Anomalías',
    'ia': 'IA',
    'ingreso': 'Ingresos',
    'sistema': 'Sistema',
  };

  String _formatTiempo(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);

    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
    if (diff.inDays < 2) return 'Ayer, ${DateFormat('h:mm a').format(fecha)}';
    return DateFormat('dd/MM/yyyy, h:mm a').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    final alertasState = ref.watch(alertasViewModelProvider);
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(alertasState, colors, font),
          Expanded(
            child: alertasState.when(
              data: (alertas) {
                final filtradas = _filtroActivo == 'todas'
                    ? alertas
                    : alertas.where((a) => a.tipo == _filtroActivo).toList();
                return _buildLista(filtradas, colors, font);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error al cargar alertas')),
            ),
          ),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Alerta>> alertasState, AppColors colors, AppFont font) {
    final noLeidas = alertasState.value?.where((a) => !a.leida).length ?? 0;

    return Container(
      color: colors.accent,
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
                      Text('Centro de alertas', style: font.h3),
                      const SizedBox(height: 2),
                      Text('$noLeidas notificaciones sin leer',
                          style: font.caption.copyWith(color: colors.accentDark)),
                    ],
                  ),
                  Row(
                    children: [
                      if (noLeidas > 0)
                        GestureDetector(
                          onTap: () async {
                            await ref.read(alertasViewModelProvider.notifier).marcarTodasComoLeidas();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Todas las alertas marcadas como leídas'),
                                backgroundColor: colors.statusNormal,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: AppTheme.radius.brSm,
                            ),
                            child: Text('Leer todas', style: font.caption.copyWith(
                                fontSize: 10, fontWeight: FontWeight.w500, color: colors.titleText)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: noLeidas > 0 ? colors.statusCritical : colors.statusNormal,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$noLeidas',
                              style: font.label.copyWith(color: colors.white, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filtros.entries.map((entry) {
                    final activo = _filtroActivo == entry.key;
                    return GestureDetector(
                      onTap: () => setState(() => _filtroActivo = entry.key),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6, bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: activo ? colors.titleText : colors.accent,
                          borderRadius: BorderRadius.circular(AppTheme.radius.full),
                          border: Border.all(
                            color: activo ? colors.titleText : colors.accentDark, width: 0.5),
                        ),
                        child: Text(entry.value,
                            style: font.caption.copyWith(
                              fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                              color: activo ? colors.white : colors.accentDark)),
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

  Widget _buildLista(List<Alerta> alertas, AppColors colors, AppFont font) {
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
        child: alertas.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined, color: colors.hint, size: 48),
                    const SizedBox(height: 12),
                    Text('Sin alertas', style: font.hint.copyWith(fontSize: 13)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
                itemCount: alertas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildAlertaCard(alertas[index], colors, font),
              ),
      ),
    );
  }

  Widget _buildAlertaCard(Alerta alerta, AppColors colors, AppFont font) {
    final config = _configPorTipo(alerta.tipo, colors);
    return Dismissible(
      key: Key(alerta.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.statusCritical,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.white, size: 22),
      ),
      onDismissed: (_) {
        ref.read(alertasViewModelProvider.notifier).eliminarAlerta(alerta.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!alerta.leida) {
            ref.read(alertasViewModelProvider.notifier).marcarComoLeida(alerta.id);
          }
        },
        child: Opacity(
          opacity: alerta.leida ? 0.7 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: alerta.leida ? colors.card : config.colorFondo,
              borderRadius: BorderRadius.circular(AppTheme.radius.lg),
              border: Border.all(
                color: alerta.leida ? colors.border : config.colorBorde, width: 0.5),
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
                          Text(alerta.titulo,
                              style: font.label.copyWith(fontSize: 12, color: config.colorIcono)),
                          if (!alerta.leida)
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                color: config.colorIcono, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(alerta.mensaje,
                          style: font.bodySmall.copyWith(
                            fontSize: 12,
                            color: alerta.leida ? colors.bodyText : colors.titleText,
                            height: 1.4,
                          )),
                      const SizedBox(height: 4),
                      Text(_formatTiempo(alerta.createdAt), style: font.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ConfigAlerta _configPorTipo(String tipo, AppColors colors) {
    switch (tipo) {
      case 'stock_bajo':
        return _ConfigAlerta(icono: Icons.warning_amber_rounded,
          colorFondo: colors.dangerLight, colorBorde: colors.dangerBorder,
          colorIcono: colors.statusCritical,
          colorIconoFondo: colors.statusCritical.withValues(alpha: 0.12));
      case 'anomalia':
        return _ConfigAlerta(icono: Icons.query_stats_rounded,
          colorFondo: colors.dangerLight, colorBorde: colors.dangerBorder,
          colorIcono: colors.statusCritical,
          colorIconoFondo: colors.statusCritical.withValues(alpha: 0.12));
      case 'ia':
        return _ConfigAlerta(icono: Icons.psychology_outlined,
          colorFondo: colors.primaryLight, colorBorde: colors.primaryBorder,
          colorIcono: colors.primary,
          colorIconoFondo: colors.primary.withValues(alpha: 0.12));
      case 'ingreso':
        return _ConfigAlerta(icono: Icons.move_to_inbox_outlined,
          colorFondo: colors.successLight, colorBorde: colors.successBorder,
          colorIcono: colors.statusNormal,
          colorIconoFondo: colors.statusNormal.withValues(alpha: 0.12));
      default:
        return _ConfigAlerta(icono: Icons.notifications_outlined,
          colorFondo: colors.bg, colorBorde: colors.border,
          colorIcono: colors.titleText,
          colorIconoFondo: colors.surface);
    }
  }
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
