import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/demo/diseno_demo.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
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
    return HoHeader(
      title: 'Inventario',
      subtitle: 'Control de insumos y materia prima',
      action: HoHeaderButton(
        label: 'Nuevo',
        icon: Icons.add_rounded,
        onTap: () => context.go('/catalogo/nuevo'),
      ),
      bottom: HoSearchField(
        controller: _searchController,
        hint: 'Buscar insumo o ingrediente...',
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(catalogoViewModelProvider.notifier).cargarArticulos(),
      child: _buildLista(context, _articulosVisibles),
    );
  }

  Widget _buildLista(BuildContext context, List<Articulo> articulos) {
    if (articulos.isEmpty) {
      final c = AppTheme.colorsOf(context);
      return ListView(
        children: [
          const SizedBox(height: 64),
          Icon(Icons.inventory_2_outlined, size: 40, color: c.hint),
          const SizedBox(height: 8),
          Text(
            'No se encontraron insumos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.bodyText,
            ),
          ),
          Text(
            'Prueba con otra búsqueda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.hint),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
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
          colorPrincipal: colors.primaryDark,
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
    final recetaAsync = ref.watch(recetaPorProductoProvider(art.id));

    final bajo = art.stockActual <= art.stockMinimo;
    final pct = art.stockMinimo <= 0
        ? 1.0
        : art.stockActual / (art.stockMinimo * 2);

    return HoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Miniatura(articulo: art, bajo: bajo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            art.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.titleText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        HoBadge(
                          text: config.etiqueta,
                          color: config.colorPrincipal,
                          background: config.colorFondo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: 'Stock: ',
                        style: TextStyle(fontSize: 12, color: colors.bodyText),
                        children: [
                          TextSpan(
                            text:
                                '${art.stockActual.toStringAsFixed(2)} ${art.unidad.dbValue}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.titleText,
                            ),
                          ),
                          TextSpan(
                            text: ' / mín. ${art.stockMinimo.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    HoProgressBar(
                      value: pct,
                      color: bajo ? colors.statusCritical : colors.statusNormal,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.bodyText,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: colors.card,
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
                    _menuItem(context, 'editar', Icons.edit_outlined, 'Editar insumo'),
                    _menuItem(
                      context,
                      'registrar_movimiento',
                      Icons.sync_alt_rounded,
                      'Registrar movimiento',
                    ),
                    _menuItem(
                      context,
                      'ver_registro',
                      Icons.history_rounded,
                      'Ver registro de movimientos',
                    ),
                    _menuItem(
                      context,
                      'eliminar',
                      Icons.delete_outline,
                      'Eliminar',
                      danger: true,
                    ),
                  ],
                ),
              ),
            ],
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

  PopupMenuItem<String> _menuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final colors = AppTheme.colorsOf(context);
    final color = danger ? colors.statusCritical : colors.titleText;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura del artículo (icono según tipo) con indicador de stock bajo.
class _Miniatura extends StatelessWidget {
  final Articulo articulo;
  final bool bajo;

  const _Miniatura({required this.articulo, required this.bajo});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final esProducto = articulo.tipo == TipoArticulo.productoFinal;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: HoPhoto(
              // TODO: foto real del artículo (hoy es foto demo por nombre).
              photoId:
                  DisenoDemo.fotoPara(articulo.nombre) ??
                  DisenoDemo.fotoPorDefecto,
              width: 64,
              height: 64,
              px: 128,
              radius: BorderRadius.circular(11),
              fallbackIcon: esProducto
                  ? Icons.bakery_dining_rounded
                  : Icons.grain_rounded,
            ),
          ),
          if (bajo)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.statusCritical,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.white, width: 2),
                ),
              ),
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
