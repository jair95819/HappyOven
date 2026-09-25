import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/core/models/enums.dart';
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
  static const _estados = ['todas', 'pendiente', 'en_proceso', 'completada', 'cancelada'];

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
            child: _filtroEstado == 'todas'
                ? recetasAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: font.body)),
                    data: (recetasList) {
                      if (recetasList.isEmpty) {
                        return _buildVacioRecetas(colors, font);
                      }
                      return _buildListaRecetas(
                        recetasList,
                        ordenesAsync.valueOrNull ?? [],
                        colors,
                        font,
                      );
                    },
                  )
                : ordenesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: font.body)),
                    data: (ordenes) {
                      final filtradas = ordenes
                          .where((o) => o.estado.dbValue == _filtroEstado)
                          .toList();
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

  /// Inicia una orden: cambia su estado a en_proceso.
  Future<void> _iniciarOrden(OrdenProduccion orden) async {
    final colors = AppTheme.colorsOf(context);
    final error = await ref.read(ordenesProduccionProvider.notifier).iniciarOrden(orden);

    if (!mounted) return;

    if (error == null) {
      setState(() => _filtroEstado = 'en_proceso');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Orden iniciada y en proceso'),
        backgroundColor: colors.statusNormal,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al iniciar: $error'),
        backgroundColor: colors.statusCritical,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Cancela una orden: cambia su estado a cancelada.
  Future<void> _cancelarOrden(OrdenProduccion orden) async {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius.lg)),
        title: Text('Cancelar Orden', style: font.h3.copyWith(color: colors.statusCritical)),
        content: const Text('¿Estás seguro de que deseas cancelar esta orden de producción? Los insumos no serán descontados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No, volver', style: font.label.copyWith(color: colors.hint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sí, cancelar', style: font.label.copyWith(color: colors.statusCritical)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final error = await ref.read(ordenesProduccionProvider.notifier).cancelarOrden(orden);

    if (!mounted) return;

    if (error == null) {
      setState(() => _filtroEstado = 'cancelada');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Orden cancelada'),
        backgroundColor: colors.statusNormal,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cancelar: $error'),
        backgroundColor: colors.statusCritical,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Ejecuta una orden pendiente/en_proceso: valida stock, descuenta insumos y registra
  /// el producto terminado. Muestra la alerta de stock insuficiente si aplica.
  Future<void> _ejecutarOrden(OrdenProduccion orden) async {
    final colors = AppTheme.colorsOf(context);

    final usuarioId = ref.read(authViewModelProvider).usuario?.id;
    if (usuarioId == null || usuarioId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No se detectó usuario autenticado. Inicia sesión nuevamente.'),
        backgroundColor: colors.statusCritical,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

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

    final error = await ref
        .read(ejecutarProduccionProvider)
        .ejecutarOrden(orden: orden, usuarioId: usuarioId);

    if (!mounted) return;

    // Refrescar siempre órdenes, inventario y dashboard para mantener el estado sincronizado
    await ref.read(ordenesProduccionProvider.notifier).cargarOrdenes();
    await ref.read(catalogoViewModelProvider.notifier).cargarArticulos();
    ref.read(dashboardViewModelProvider.notifier).cargarDatos();

    if (!mounted) return;

    if (error == null) {
      setState(() => _filtroEstado = 'completada');

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
      ));
    }
  }

  /// Muestra diálogo para seleccionar la cantidad de lotes y crear la orden.
  Future<void> _mostrarDialogoEjecutar(Receta receta) async {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    final textController = TextEditingController(text: '1');

    final lotes = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius.lg)),
        title: Text(
          'Ejecutar Producción',
          style: font.h3.copyWith(color: colors.titleText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receta: ${receta.nombre}',
              style: font.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Cantidad de lotes a producir:',
              style: font.caption.copyWith(color: colors.hint),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              style: font.body,
              decoration: InputDecoration(
                hintText: 'Ej. 1',
                hintStyle: font.caption,
                filled: true,
                fillColor: colors.bg,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.radius.brSm,
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.radius.brSm,
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: font.label.copyWith(color: colors.hint)),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(textController.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: const Text('Por favor ingresa un número de lotes válido mayor a 0'),
                  backgroundColor: colors.statusCritical,
                ));
              }
            },
            child: Text('Confirmar', style: font.label.copyWith(color: colors.primary)),
          ),
        ],
      ),
    );

    if (lotes == null) return;

    final usuarioId = ref.read(authViewModelProvider).usuario?.id;
    if (usuarioId == null || usuarioId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No se detectó usuario autenticado. Inicia sesión nuevamente.'),
        backgroundColor: AppTheme.colorsOf(context).statusCritical,
      ));
      return;
    }
    final orden = OrdenProduccion(
      id: '',
      recetaId: receta.id,
      usuarioId: usuarioId,
      cantidadLotes: lotes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final error = await ref.read(ordenesProduccionProvider.notifier).crearOrden(orden);

    if (!mounted) return;

    if (error == null) {
      setState(() => _filtroEstado = 'pendiente');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Orden creada y llevada a Pendientes'),
        backgroundColor: colors.statusNormal,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'),
        backgroundColor: colors.statusCritical,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildFiltros(AppColors colors, AppFont font) {
    const filtros = _estados;
    final etiquetas = {
      'todas': 'Todas',
      'pendiente': 'Pendientes',
      'en_proceso': 'En Proceso',
      'completada': 'Completadas',
      'cancelada': 'Canceladas',
    };

    return Container(
      color: colors.khakiSoft,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.khaki, colors.khakiSoft],
        ),
      ),
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
                    color: colors.primary,
                    borderRadius: AppTheme.radius.brSm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Nueva', style: font.label.copyWith(color: colors.white, fontSize: 13)),
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

  Widget _buildVacioRecetas(AppColors colors, AppFont font) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, color: colors.hint, size: 48),
          const SizedBox(height: 12),
          Text('Sin recetas registradas', style: font.label),
          const SizedBox(height: 4),
          Text('Crea una receta en la pestaña Recetas', style: font.caption),
        ],
      ),
    );
  }

  Widget _buildListaRecetas(
    List<Receta> recetas,
    List<OrdenProduccion> ordenes,
    AppColors colors,
    AppFont font,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(AppTheme.spacing.md, AppTheme.spacing.lg, AppTheme.spacing.md, AppTheme.spacing.sm),
          itemCount: recetas.length,
          itemBuilder: (_, i) => _buildTarjetaReceta(recetas[i], ordenes, colors, font),
        ),
      ),
    );
  }

  Widget _buildTarjetaReceta(
    Receta receta,
    List<OrdenProduccion> ordenes,
    AppColors colors,
    AppFont font,
  ) {
    final ordenesActivas = ordenes
        .where((o) =>
            o.recetaId == receta.id &&
            (o.estado == EstadoOrden.pendiente || o.estado == EstadoOrden.enProceso))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: AppTheme.shadows.cardSm,
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
                    color: colors.primaryLight,
                    borderRadius: AppTheme.radius.brMd,
                  ),
                  child: Icon(Icons.restaurant_menu_rounded, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receta.nombre,
                        style: font.label.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rendimiento: ${receta.rendimiento.toInt()} unid. · Tiempo: ${receta.tiempoProduccionMin} min',
                        style: font.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (ordenesActivas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.statusLow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.statusLow.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Activa (${ordenesActivas.length})',
                      style: font.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.statusLow,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            if (receta.instrucciones != null && receta.instrucciones!.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacing.md),
              Text(
                receta.instrucciones!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: font.caption.copyWith(fontSize: 10, color: colors.hint),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => _mostrarDialogoEjecutar(receta),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Ejecutar producción',
                        style: font.label.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(
    List<OrdenProduccion> ordenes,
    List<Receta> recetas,
    AppColors colors,
    AppFont font,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(AppTheme.spacing.md, AppTheme.spacing.lg, AppTheme.spacing.md, AppTheme.spacing.sm),
          itemCount: ordenes.length,
          itemBuilder: (_, i) => _buildTarjeta(ordenes[i], recetas, colors, font),
        ),
      ),
    );
  }

  Widget _buildTarjeta(
    OrdenProduccion orden,
    List<Receta> recetas,
    AppColors colors,
    AppFont font,
  ) {
    Receta? receta;
    try {
      receta = recetas.firstWhere((r) => r.id == orden.recetaId);
    } catch (_) {}

    final config = _configEstado(orden.estado, colors);
    final dateFmt = DateFormat('dd MMM yyyy', 'es');
    final dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a', 'es');

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: AppTheme.shadows.cardSm,
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
            SizedBox(height: AppTheme.spacing.md),
            // Dates section
            () {
              if (orden.estado == EstadoOrden.pendiente) {
                return Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: colors.hint),
                    const SizedBox(width: 4),
                    Text(
                      orden.fechaProgramada != null
                          ? 'Programada: ${dateFmt.format(orden.fechaProgramada!)}'
                          : 'Creada: ${dateTimeFmt.format(orden.createdAt)}',
                      style: font.caption.copyWith(fontSize: 10),
                    ),
                  ],
                );
              } else if (orden.estado == EstadoOrden.enProceso) {
                return Row(
                  children: [
                    Icon(Icons.play_circle_outline, size: 12, color: colors.statusLow),
                    const SizedBox(width: 4),
                    Text(
                      orden.fechaInicio != null
                          ? 'Iniciada: ${dateTimeFmt.format(orden.fechaInicio!)}'
                          : 'Iniciada: Sin fecha',
                      style: font.caption.copyWith(fontSize: 10),
                    ),
                  ],
                );
              } else if (orden.estado == EstadoOrden.completada) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 12, color: colors.hint),
                        const SizedBox(width: 4),
                        Text(
                          orden.fechaInicio != null
                              ? 'Iniciada: ${dateTimeFmt.format(orden.fechaInicio!)}'
                              : 'Iniciada: Sin fecha',
                          style: font.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 12, color: colors.statusNormal),
                        const SizedBox(width: 4),
                        Text(
                          orden.fechaFin != null
                              ? 'Completada: ${dateTimeFmt.format(orden.fechaFin!)}'
                              : 'Completada: Sin fecha',
                          style: font.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 12, color: colors.statusCritical),
                    const SizedBox(width: 4),
                    Text(
                      orden.fechaFin != null
                          ? 'Cancelada: ${dateTimeFmt.format(orden.fechaFin!)}'
                          : 'Cancelada: Sin fecha',
                      style: font.caption.copyWith(fontSize: 10),
                    ),
                  ],
                );
              }
            }(),
            if (orden.notas != null && orden.notas!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(orden.notas!, style: font.caption.copyWith(fontSize: 10)),
            ],
            // Actions section
            () {
              if (orden.estado == EstadoOrden.pendiente) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => _iniciarOrden(orden),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: AppTheme.radius.brSm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Iniciar',
                              style: font.label.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else if (orden.estado == EstadoOrden.enProceso) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _cancelarOrden(orden),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: colors.bg,
                              borderRadius: AppTheme.radius.brSm,
                              border: Border.all(color: colors.statusCritical),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, color: colors.statusCritical, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Cancelar',
                                  style: font.label.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.statusCritical,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _ejecutarOrden(orden),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: colors.statusNormal,
                              borderRadius: AppTheme.radius.brSm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, color: colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Completar',
                                  style: font.label.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }(),
          ],
        ),
      ),
    );
  }

  _ConfigEstado _configEstado(EstadoOrden estado, AppColors colors) {
    switch (estado) {
      case EstadoOrden.pendiente:
        return _ConfigEstado(
          icono: Icons.schedule_rounded,
          colorPrincipal: colors.primary,
          colorFondo: colors.primaryLight,
          etiqueta: 'Pendiente',
        );
      case EstadoOrden.enProceso:
        return _ConfigEstado(
          icono: Icons.play_circle_outline,
          colorPrincipal: colors.statusLow,
          colorFondo: const Color(0xFFFFF3E0),
          etiqueta: 'En Proceso',
        );
      case EstadoOrden.completada:
        return _ConfigEstado(
          icono: Icons.check_circle_outline,
          colorPrincipal: colors.statusNormal,
          colorFondo: colors.successLight,
          etiqueta: 'Completada',
        );
      case EstadoOrden.cancelada:
        return _ConfigEstado(
          icono: Icons.cancel_outlined,
          colorPrincipal: colors.statusCritical,
          colorFondo: colors.dangerLight,
          etiqueta: 'Cancelada',
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
