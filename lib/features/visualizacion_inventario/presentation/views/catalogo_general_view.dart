import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';

class CatalogoGeneralView extends ConsumerStatefulWidget {
  const CatalogoGeneralView({super.key});

  @override
  ConsumerState<CatalogoGeneralView> createState() =>
      _CatalogoGeneralViewState();
}

class _CatalogoGeneralViewState extends ConsumerState<CatalogoGeneralView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Articulo> _todosArticulos = [];

  List<Articulo> _deduplicarArticulos(List<Articulo> articulos) {
    final vistos = <String>{};
    final sinDuplicados = <Articulo>[];

    for (final articulo in articulos) {
      final clave =
          (articulo.id.isNotEmpty
                  ? articulo.id
                  : articulo.nombre.trim().toLowerCase())
              .trim();

      if (clave.isEmpty || !vistos.add(clave)) {
        continue;
      }

      sinDuplicados.add(articulo);
    }

    return sinDuplicados;
  }

  List<Articulo> get _insumosFiltrados => _deduplicarArticulos(
    _todosArticulos
        .where(
          (a) =>
              a.tipo == TipoArticulo.insumo &&
              a.nombre.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(),
  );

  List<Articulo> get _productosFiltrados => _deduplicarArticulos(
    _todosArticulos
        .where(
          (a) =>
              a.tipo == TipoArticulo.productoFinal &&
              a.nombre.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(),
  );

  List<Articulo> get _articulosVisibles => _deduplicarArticulos(
    _todosArticulos
        .where((a) => a.nombre.toLowerCase().contains(_query.toLowerCase()))
        .toList(),
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _EstadoStock _estadoDeArticulo(Articulo a) {
    final ratio = a.stockActual / a.stockMinimo;
    if (ratio <= 0.5) return _EstadoStock.critico;
    if (ratio <= 1.0) return _EstadoStock.bajo;
    return _EstadoStock.normal;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogoViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: state.when(
              data: (articulos) {
                _todosArticulos = _deduplicarArticulos(articulos);
                return _buildBody(context);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: AppTheme.fontOf(context).body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Container(
      color: const Color(0xFFF5F1EA),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventario',
                        style: font.h1.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: colors.titleText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control de insumos y materia prima',
                        style: font.caption.copyWith(
                          fontSize: 12,
                          color: colors.hint,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/catalogo/nuevo'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2B2B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nuevo',
                            style: font.label.copyWith(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E4DF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  style: font.bodySmall.copyWith(
                    fontSize: 14,
                    color: colors.titleText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar insumo o ingrediente...',
                    hintStyle: font.hint.copyWith(
                      fontSize: 14,
                      color: colors.hint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.hint,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      color: const Color(0xFFEFEAE5),
      child: _buildLista(context, _articulosVisibles),
    );
  }

  Widget _buildLista(BuildContext context, List<Articulo> articulos) {
    if (articulos.isEmpty) {
      return Center(
        child: Text(
          'Sin resultados',
          style: AppTheme.fontOf(context).hint.copyWith(fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      itemCount: articulos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final art = articulos[index];
        final estado = _estadoDeArticulo(art);
        final config = _configPorEstado(context, estado);

        return _ProductoFinalCard(
          articulo: art,
          config: config,
          onEdit: () => context.go('/catalogo/nuevo', extra: art),
          onDelete: () => _eliminarArticulo(context, art.id),
        );
      },
    );
  }

  void _eliminarArticulo(BuildContext context, String id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar artículo'),
        content: const Text(
          '¿Estás seguro de eliminar este artículo del inventario? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              'Eliminar',
              style: TextStyle(
                color: AppTheme.colorsOf(context).statusCritical,
              ),
            ),
          ),
        ],
      ),
    );

    if (conf == true) {
      final exito = await ref
          .read(catalogoViewModelProvider.notifier)
          .eliminarArticulo(id);
      if (!context.mounted) return;
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Artículo eliminado'),
            backgroundColor: AppTheme.colorsOf(context).statusCritical,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al eliminar'),
            backgroundColor: AppTheme.colorsOf(context).statusCritical,
          ),
        );
      }
    }
  }

  Widget _buildTarjetaArticulo(BuildContext context, Articulo articulo) {
    final estado = _estadoDeArticulo(articulo);
    final config = _configPorEstado(context, estado);
    final font = AppTheme.fontOf(context);
    final colors = AppTheme.colorsOf(context);
    final ratio = (articulo.stockActual / articulo.stockMinimo).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  articulo.nombre,
                  style: font.label.copyWith(fontSize: 15, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: config.colorFondo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  config.etiqueta,
                  style: font.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: config.colorPrincipal,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.hint,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'editar') {
                    context.go('/catalogo/nuevo', extra: articulo);
                  } else if (val == 'registrar_movimiento') {
                    context.push(
                      '/catalogo/movimiento/${articulo.id}',
                      extra: articulo,
                    );
                  } else if (val == 'ver_registro') {
                    context.push('/catalogo/historial/${articulo.id}');
                  } else if (val == 'eliminar') {
                    _eliminarArticulo(context, articulo.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Editar', style: font.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'registrar_movimiento',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Registrar movimiento', style: font.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ver_registro',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: colors.primaryBorder,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ver registro de movimientos',
                          style: font.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.statusCritical,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: font.bodySmall.copyWith(
                            color: colors.statusCritical,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stock: ${articulo.stockActual} / mín. ${articulo.stockMinimo} ${articulo.unidad.dbValue}',
            style: font.caption.copyWith(fontSize: 12, color: colors.hint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(config.colorPrincipal),
            ),
          ),
        ],
      ),
    );
  }

  _ConfigEstado _configPorEstado(BuildContext context, _EstadoStock estado) {
    final colors = AppTheme.colorsOf(context);
    switch (estado) {
      case _EstadoStock.critico:
        return _ConfigEstado(
          etiqueta: 'Crítico',
          colorPrincipal: colors.statusCritical,
          colorFondo: colors.dangerLight,
        );
      case _EstadoStock.bajo:
        return _ConfigEstado(
          etiqueta: 'Bajo',
          colorPrincipal: colors.primary,
          colorFondo: colors.primaryLight,
        );
      case _EstadoStock.normal:
        return _ConfigEstado(
          etiqueta: 'Normal',
          colorPrincipal: colors.statusNormal,
          colorFondo: colors.successLight,
        );
    }
  }
}

enum _EstadoStock { critico, bajo, normal }

class _ConfigEstado {
  final String etiqueta;
  final Color colorPrincipal;
  final Color colorFondo;
  const _ConfigEstado({
    required this.etiqueta,
    required this.colorPrincipal,
    required this.colorFondo,
  });
}

// ── Widget para tarjeta de producto final con desglose de receta ──

class _ProductoFinalCard extends ConsumerStatefulWidget {
  final Articulo articulo;
  final _ConfigEstado config;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductoFinalCard({
    required this.articulo,
    required this.config,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_ProductoFinalCard> createState() => _ProductoFinalCardState();
}

class _ProductoFinalCardState extends ConsumerState<_ProductoFinalCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final font = AppTheme.fontOf(context);
    final colors = AppTheme.colorsOf(context);
    final art = widget.articulo;
    final config = widget.config;
    final ratio = (art.stockActual / art.stockMinimo).clamp(0.0, 1.0);
    final recetaAsync = ref.watch(recetaPorProductoProvider(art.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  art.nombre,
                  style: font.label.copyWith(fontSize: 15, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: config.colorFondo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  config.etiqueta,
                  style: font.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: config.colorPrincipal,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.hint,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'editar') {
                    widget.onEdit();
                  } else if (val == 'registrar_movimiento') {
                    context.push('/catalogo/movimiento/${art.id}', extra: art);
                  } else if (val == 'ver_registro') {
                    context.push('/catalogo/historial/${art.id}');
                  } else if (val == 'eliminar') {
                    widget.onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Editar', style: font.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'registrar_movimiento',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Registrar movimiento', style: font.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ver_registro',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: colors.primaryBorder,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ver registro de movimientos',
                          style: font.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.statusCritical,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: font.bodySmall.copyWith(
                            color: colors.statusCritical,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stock: ${art.stockActual} / mín. ${art.stockMinimo} ${art.unidad.dbValue}',
            style: font.caption.copyWith(fontSize: 12, color: colors.hint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(config.colorPrincipal),
            ),
          ),
          recetaAsync.when(
            data: (receta) {
              if (receta == null) return const SizedBox.shrink();
              return _RecetaSection(
                receta: receta,
                expandido: _expandido,
                onToggle: () => setState(() => _expandido = !_expandido),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Buscando receta...',
                    style: font.caption.copyWith(
                      fontSize: 11,
                      color: colors.hint,
                    ),
                  ),
                ],
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RecetaSection extends ConsumerWidget {
  final Receta receta;
  final bool expandido;
  final VoidCallback onToggle;

  const _RecetaSection({
    required this.receta,
    required this.expandido,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    final ingredientesAsync = ref.watch(ingredientesRecetaProvider(receta.id));
    final articulosAsync = ref.watch(catalogoViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 14, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'Receta: ${receta.nombre}',
                style: font.label.copyWith(fontSize: 12, color: colors.primary),
              ),
              const Spacer(),
              Text(
                'Rinde: ${receta.rendimiento.toInt()} unid.',
                style: font.caption.copyWith(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Icon(
                expandido ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: colors.hint,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expandido
              ? ingredientesAsync.when(
                  data: (ingredientes) {
                    if (ingredientes.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Sin ingredientes registrados',
                          style: font.caption.copyWith(
                            fontSize: 11,
                            color: colors.hint,
                          ),
                        ),
                      );
                    }
                    final articulos = articulosAsync.valueOrNull ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: ingredientes.map((ing) {
                          Articulo? insumo;
                          try {
                            insumo = articulos.firstWhere(
                              (a) => a.id == ing.insumoId,
                            );
                          } catch (_) {}
                          final costo = insumo != null
                              ? insumo.precioUnitario * ing.cantidadRequerida
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle_outlined,
                                    size: 8,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      insumo?.nombre ?? '---',
                                      style: font.bodySmall.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${ing.cantidadRequerida} ${insumo?.unidad.dbValue ?? ''}',
                                    style: font.label.copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'S/ ${costo.toStringAsFixed(2)}',
                                    style: font.caption.copyWith(
                                      fontSize: 10,
                                      color: colors.hint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cargando ingredientes...',
                          style: font.caption.copyWith(
                            fontSize: 11,
                            color: colors.hint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error al cargar ingredientes',
                      style: font.caption.copyWith(
                        fontSize: 11,
                        color: colors.statusCritical,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
