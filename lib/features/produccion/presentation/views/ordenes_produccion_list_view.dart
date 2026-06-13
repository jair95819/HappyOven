import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/features/produccion/presentation/viewmodels/produccion_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/dashboard_viewmodel.dart';

class OrdenesProduccionListView extends ConsumerStatefulWidget {
  const OrdenesProduccionListView({super.key});

  @override
  ConsumerState<OrdenesProduccionListView> createState() => _OrdenesProduccionListViewState();
}

class _OrdenesProduccionListViewState extends ConsumerState<OrdenesProduccionListView> {
  String _filtroEstado = 'todas';

  @override
  Widget build(BuildContext context) {
    final ordenesAsync = ref.watch(ordenesProduccionProvider);
    final recetasAsync = ref.watch(recetasViewModelProvider);
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    final recetas = recetasAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(colors, font, ordenesAsync),
          _buildFiltros(colors, font),
          Expanded(
            child: ordenesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: font.body)),
              data: (ordenes) {
                final filtradas = _filtroEstado == 'todas'
                    ? ordenes
                    : ordenes.where((o) => o.estado == _filtroEstado).toList();
                if (filtradas.isEmpty) {
                  return _buildVacio(colors, font);
                }
                return _buildLista(filtradas, recetas, colors, font);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Ejecuta una orden pendiente: valida stock, descuenta insumos y registra
  /// el producto terminado. Muestra la alerta de stock insuficiente si aplica.
  Future<void> _ejecutarOrden(OrdenProduccion orden) async {
    final colors = AppTheme.colorsOf(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar producción'),
        content: const Text(
          'Se descontarán automáticamente los insumos del inventario y se '
          'registrará el producto terminado. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ejecutar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final usuarioId = ref.read(authViewModelProvider).usuario?.id ?? '';
    final error = await ref
        .read(ejecutarProduccionProvider)
        .ejecutarOrden(orden: orden, usuarioId: usuarioId);

    if (!mounted) return;

    if (error == null) {
      // Refrescar órdenes, inventario y dashboard para ver el stock en tiempo real.
      await ref.read(ordenesProduccionProvider.notifier).cargarOrdenes();
      await ref.read(catalogoViewModelProvider.notifier).cargarArticulos();
      ref.read(dashboardViewModelProvider.notifier).cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Producción ejecutada y stock actualizado'),
        backgroundColor: colors.statusNormal,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: colors.statusCritical,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Widget _buildFiltros(AppColors colors, AppFont font) {
    final filtros = ['todas', 'pendiente', 'en_proceso', 'completada', 'cancelada'];
    final etiquetas = {
      'todas': 'Todas',
      'pendiente': 'Pendientes',
      'en_proceso': 'En Proceso',
      'completada': 'Completadas',
      'cancelada': 'Canceladas',
    };

    return Container(
      color: colors.accent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius.md)),
        ),
        child: SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: filtros.map((f) {
              final activo = _filtroEstado == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filtroEstado = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo ? colors.primary : colors.card,
                      borderRadius: AppTheme.radius.brSm,
                      border: Border.all(color: activo ? colors.primary : colors.border),
                    ),
                    child: Text(
                      etiquetas[f]!,
                      style: font.label.copyWith(
                        fontSize: 12,
                        color: activo ? colors.white : colors.hint,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors, AppFont font, AsyncValue<List<OrdenProduccion>> ordenesAsync) {
    final total = ordenesAsync.valueOrNull?.length ?? 0;
    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Órdenes de Producción', style: font.h3),
                  const SizedBox(height: 2),
                  Text('$total órdenes registradas', style: font.caption.copyWith(color: colors.accentDark)),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/produccion/nueva'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: colors.titleText,
                    borderRadius: AppTheme.radius.brSm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: colors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text('Nueva', style: font.label.copyWith(color: colors.accent, fontSize: 13)),
                    ],
                  ),
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
          Icon(Icons.factory_outlined, color: colors.hint, size: 48),
          const SizedBox(height: 12),
          Text('Sin órdenes de producción', style: font.label),
          const SizedBox(height: 4),
          Text('Crea una orden desde una receta', style: font.caption),
        ],
      ),
    );
  }

  Widget _buildLista(List<OrdenProduccion> ordenes, List<Receta> recetas, AppColors colors, AppFont font) {
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
          itemCount: ordenes.length,
          itemBuilder: (_, i) => _buildTarjeta(ordenes[i], recetas, colors, font),
        ),
      ),
    );
  }

  Widget _buildTarjeta(OrdenProduccion orden, List<Receta> recetas, AppColors colors, AppFont font) {
    Receta? receta;
    try {
      receta = recetas.firstWhere((r) => r.id == orden.recetaId);
    } catch (_) {}

    final config = _configEstado(orden.estado, colors);
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: config.colorFondo,
                    borderRadius: AppTheme.radius.brMd,
                  ),
                  child: Icon(config.icono, color: config.colorPrincipal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receta?.nombre ?? 'Receta #${orden.recetaId.substring(0, 8)}',
                        style: font.label.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${orden.cantidadLotes} lote(s) · ${orden.cantidadProducida > 0 ? '${orden.cantidadProducida} unid. producidas' : 'Sin producir'}',
                        style: font.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.colorFondo,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: config.colorPrincipal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    config.etiqueta,
                    style: font.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: config.colorPrincipal,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: colors.hint),
                const SizedBox(width: 4),
                Text(
                  orden.fechaProgramada != null
                      ? fmt.format(orden.fechaProgramada!)
                      : 'Sin fecha programada',
                  style: font.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
            if (orden.notas != null && orden.notas!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(orden.notas!, style: font.caption.copyWith(fontSize: 10)),
            ],
            if (orden.estado == 'pendiente') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => _ejecutarOrden(orden),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: AppTheme.radius.brSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: colors.titleText, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Ejecutar producción',
                          style: font.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.titleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ConfigEstado _configEstado(String estado, AppColors colors) {
    switch (estado) {
      case 'pendiente':
        return _ConfigEstado(
          icono: Icons.schedule_rounded,
          colorPrincipal: colors.primary,
          colorFondo: colors.primaryLight,
          etiqueta: 'Pendiente',
        );
      case 'en_proceso':
        return _ConfigEstado(
          icono: Icons.play_circle_outline,
          colorPrincipal: colors.statusLow,
          colorFondo: const Color(0xFFFFF3E0),
          etiqueta: 'En Proceso',
        );
      case 'completada':
        return _ConfigEstado(
          icono: Icons.check_circle_outline,
          colorPrincipal: colors.statusNormal,
          colorFondo: colors.successLight,
          etiqueta: 'Completada',
        );
      case 'cancelada':
        return _ConfigEstado(
          icono: Icons.cancel_outlined,
          colorPrincipal: colors.statusCritical,
          colorFondo: colors.dangerLight,
          etiqueta: 'Cancelada',
        );
      default:
        return _ConfigEstado(
          icono: Icons.help_outline,
          colorPrincipal: colors.hint,
          colorFondo: colors.surface,
          etiqueta: estado,
        );
    }
  }
}

class _ConfigEstado {
  final IconData icono;
  final Color colorPrincipal;
  final Color colorFondo;
  final String etiqueta;

  const _ConfigEstado({
    required this.icono,
    required this.colorPrincipal,
    required this.colorFondo,
    required this.etiqueta,
  });
}
