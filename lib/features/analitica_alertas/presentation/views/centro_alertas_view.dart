import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/alerta.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/alertas_viewmodel.dart';
import 'package:intl/intl.dart';

class CentroAlertasView extends ConsumerStatefulWidget {
  const CentroAlertasView({super.key});

  @override
  ConsumerState<CentroAlertasView> createState() => _CentroAlertasViewState();
}

class _CentroAlertasViewState extends ConsumerState<CentroAlertasView> {
  TipoAlerta? _filtroActivo;

  /// IDs de alertas actualmente expandidas
  final Set<String> _expandedIds = {};

  /// Cache de artículos ya consultados para no repetir peticiones
  final Map<String, Articulo?> _articulosCache = {};

  final Map<TipoAlerta?, String> _filtros = {
    null: 'Todas',
    TipoAlerta.stockBajo: 'Stock bajo',
    TipoAlerta.anomalia: 'Anomalías',
    TipoAlerta.ia: 'IA',
    TipoAlerta.ingreso: 'Ingresos',
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

  Future<void> _cargarArticulo(String articuloId) async {
    if (_articulosCache.containsKey(articuloId)) return;
    try {
      final repo = ref.read(articulosRepositoryProvider);
      final articulo = await repo.getArticuloById(articuloId);
      if (mounted) {
        setState(() {
          _articulosCache[articuloId] = articulo;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _articulosCache[articuloId] = null;
        });
      }
    }
  }

  void _toggleExpanded(Alerta alerta) {
    setState(() {
      if (_expandedIds.contains(alerta.id)) {
        _expandedIds.remove(alerta.id);
      } else {
        _expandedIds.add(alerta.id);
        // Si es stock bajo y tiene articuloId, cargar el artículo
        if (alerta.tipo == TipoAlerta.stockBajo && alerta.articuloId != null) {
          _cargarArticulo(alerta.articuloId!);
        }
      }
    });

    if (!alerta.leida) {
      ref.read(alertasViewModelProvider.notifier).marcarComoLeida(alerta.id);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                final filtradas = _filtroActivo == null
                    ? alertas
                    : alertas.where((a) => a.tipo == _filtroActivo).toList();
                return _buildLista(filtradas, colors, font);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Error al cargar alertas')),
            ),
          ),
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
                    final activo = (_filtroActivo == entry.key) || (_filtroActivo == null && entry.key == null);
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
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildAlertaCard(alertas[index], colors, font),
              ),
      ),
    );
  }

  Widget _buildAlertaCard(Alerta alerta, AppColors colors, AppFont font) {
    final config = _configPorTipo(alerta.tipo, colors);
    final isExpanded = _expandedIds.contains(alerta.id);

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
        onTap: () => _toggleExpanded(alerta),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: alerta.leida ? 0.7 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: alerta.leida ? colors.card : config.colorFondo,
              borderRadius: BorderRadius.circular(AppTheme.radius.lg),
              border: Border.all(
                color: isExpanded
                    ? config.colorIcono
                    : (alerta.leida ? colors.border : config.colorBorde),
                width: isExpanded ? 1.0 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                              Expanded(
                                child: Text(alerta.titulo,
                                    style: font.label.copyWith(fontSize: 12, color: config.colorIcono)),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!alerta.leida)
                                    Container(
                                      width: 7, height: 7,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: config.colorIcono, shape: BoxShape.circle),
                                    ),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 250),
                                    child: Icon(
                                      Icons.expand_more_rounded,
                                      size: 18,
                                      color: config.colorIcono.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(alerta.mensaje,
                              maxLines: isExpanded ? null : 2,
                              overflow: isExpanded ? null : TextOverflow.ellipsis,
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
                // ── Sección expandida con detalles del artículo
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildDetalleExpandido(alerta, colors, font, config),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la sección de detalles que se muestra al expandir una alerta.
  Widget _buildDetalleExpandido(Alerta alerta, AppColors colors, AppFont font, _ConfigAlerta config) {
    // Si la alerta tiene articuloId (típico de stock bajo), mostrar info del artículo
    if (alerta.articuloId != null && alerta.tipo == TipoAlerta.stockBajo) {
      final articulo = _articulosCache[alerta.articuloId];
      if (articulo == null && !_articulosCache.containsKey(alerta.articuloId)) {
        return const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        );
      }

      if (articulo == null) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('No se pudo obtener información del artículo.',
              style: font.caption.copyWith(fontStyle: FontStyle.italic)),
        );
      }

      final ratio = articulo.stockMinimo > 0
          ? (articulo.stockActual / articulo.stockMinimo).clamp(0.0, 1.0)
          : 0.0;
      final esCritico = ratio <= 0.5;

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppTheme.radius.md),
            border: Border.all(color: colors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: config.colorIcono),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(articulo.nombre,
                        style: font.label.copyWith(fontSize: 13, color: colors.titleText)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: esCritico
                          ? colors.statusCritical.withValues(alpha: 0.12)
                          : colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      esCritico ? 'Crítico' : 'Bajo',
                      style: font.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: esCritico ? colors.statusCritical : colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Barra de progreso visual
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: colors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    esCritico ? colors.statusCritical : colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDetalleItem(
                      font, colors,
                      label: 'Stock actual',
                      value: '${articulo.stockActual.toStringAsFixed(1)} ${articulo.unidad.dbValue}',
                      valueColor: esCritico ? colors.statusCritical : colors.titleText,
                    ),
                  ),
                  Expanded(
                    child: _buildDetalleItem(
                      font, colors,
                      label: 'Stock mínimo',
                      value: '${articulo.stockMinimo.toStringAsFixed(1)} ${articulo.unidad.dbValue}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildDetalleItem(
                      font, colors,
                      label: 'Precio unitario',
                      value: 'S/ ${articulo.precioUnitario.toStringAsFixed(2)}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetalleItem(
                      font, colors,
                      label: 'Faltante',
                      value: '${(articulo.stockMinimo - articulo.stockActual).clamp(0, double.infinity).toStringAsFixed(1)} ${articulo.unidad.dbValue}',
                      valueColor: colors.statusCritical,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Para otros tipos de alerta, simplemente mostrar el mensaje completo
    return const SizedBox.shrink();
  }

  Widget _buildDetalleItem(AppFont font, AppColors colors, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: font.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: font.label.copyWith(
          fontSize: 12,
          color: valueColor ?? colors.titleText,
        )),
      ],
    );
  }

  _ConfigAlerta _configPorTipo(TipoAlerta tipo, AppColors colors) {
    switch (tipo) {
      case TipoAlerta.stockBajo:
        return _ConfigAlerta(icono: Icons.warning_amber_rounded,
          colorFondo: colors.dangerLight, colorBorde: colors.dangerBorder,
          colorIcono: colors.statusCritical,
          colorIconoFondo: colors.statusCritical.withValues(alpha: 0.12));
      case TipoAlerta.anomalia:
        return _ConfigAlerta(icono: Icons.query_stats_rounded,
          colorFondo: colors.dangerLight, colorBorde: colors.dangerBorder,
          colorIcono: colors.statusCritical,
          colorIconoFondo: colors.statusCritical.withValues(alpha: 0.12));
      case TipoAlerta.ia:
        return _ConfigAlerta(icono: Icons.psychology_outlined,
          colorFondo: colors.primaryLight, colorBorde: colors.primaryBorder,
          colorIcono: colors.primary,
          colorIconoFondo: colors.primary.withValues(alpha: 0.12));
      case TipoAlerta.ingreso:
        return _ConfigAlerta(icono: Icons.move_to_inbox_outlined,
          colorFondo: colors.successLight, colorBorde: colors.successBorder,
          colorIcono: colors.statusNormal,
          colorIconoFondo: colors.statusNormal.withValues(alpha: 0.12));
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
