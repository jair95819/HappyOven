import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class CatalogoGeneralView extends ConsumerStatefulWidget {
  const CatalogoGeneralView({super.key});

  @override
  ConsumerState<CatalogoGeneralView> createState() => _CatalogoGeneralViewState();
}

class _CatalogoGeneralViewState extends ConsumerState<CatalogoGeneralView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Articulo> _todosArticulos = [];

  List<Articulo> get _insumosFiltrados =>
      _todosArticulos.where((a) => a.tipo == 'insumo' && a.nombre.toLowerCase().contains(_query.toLowerCase())).toList();
  List<Articulo> get _productosFiltrados =>
      _todosArticulos.where((a) => a.tipo == 'producto_final' && a.nombre.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() => _query = _searchController.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final rutaActual = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: state.when(
              data: (articulos) {
                _todosArticulos = articulos;
                return _buildBody(context);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err', style: AppTheme.fontOf(context).body)),
            ),
          ),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catálogo', style: font.h3),
                      const SizedBox(height: 2),
                      Text('Maestro de artículos',
                          style: font.caption.copyWith(color: colors.accentDark)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/catalogo/nuevo'),
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
                          Text('Nuevo', style: font.label.copyWith(
                            color: colors.accent, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: AppTheme.radius.brSm,
                ),
                child: TextField(
                  controller: _searchController,
                  style: font.bodySmall.copyWith(
                    fontSize: 13, color: colors.titleText),
                  decoration: InputDecoration(
                    hintText: 'Buscar artículo...',
                    hintStyle: font.hint.copyWith(fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.hint, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: colors.titleText,
              unselectedLabelColor: colors.hint,
              labelStyle: font.label.copyWith(fontSize: 13),
              unselectedLabelStyle: font.bodySmall.copyWith(fontSize: 13),
              indicatorColor: colors.titleText,
              indicatorWeight: 2.5,
              dividerColor: colors.border,
              tabs: const [Tab(text: 'Insumos'), Tab(text: 'Productos finales')],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).bg,
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
        child: TabBarView(
          controller: _tabController,
          children: [_buildLista(context, _insumosFiltrados), _buildLista(context, _productosFiltrados)],
        ),
      ),
    );
  }

  Widget _buildLista(BuildContext context, List<Articulo> articulos) {
    if (articulos.isEmpty) {
      return Center(child: Text('Sin resultados', style: AppTheme.fontOf(context).hint.copyWith(fontSize: 13)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
      itemCount: articulos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildTarjetaArticulo(context, articulos[index]),
    );
  }

  void _eliminarArticulo(BuildContext context, String id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar artículo'),
        content: const Text('¿Estás seguro de eliminar este artículo del inventario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Eliminar', style: TextStyle(color: AppTheme.colorsOf(context).statusCritical))),
        ],
      ),
    );

    if (conf == true) {
      final exito = await ref.read(catalogoViewModelProvider.notifier).eliminarArticulo(id);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Artículo eliminado'), backgroundColor: AppTheme.colorsOf(context).statusCritical));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Error al eliminar'), backgroundColor: AppTheme.colorsOf(context).statusCritical));
        }
      }
    }
  }

  Widget _buildTarjetaArticulo(BuildContext context, Articulo articulo) {
    final estado = _estadoDeArticulo(articulo);
    final config = _configPorEstado(context, estado);
    final font = AppTheme.fontOf(context);
    final colors = AppTheme.colorsOf(context);
    
    // Icono basado en el tipo
    final icono = articulo.tipo == 'insumo' ? Icons.inventory_2_outlined : Icons.breakfast_dining_outlined;

    final ratio = (articulo.stockActual / articulo.stockMinimo).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: config.colorFondo,
              borderRadius: AppTheme.radius.brMd,
            ),
            child: Icon(icono, color: config.colorPrincipal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(articulo.nombre, style: font.label.copyWith(fontSize: 13)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: config.colorFondo,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(config.etiqueta,
                              style: font.caption.copyWith(
                                fontWeight: FontWeight.w500, color: config.colorPrincipal)),
                        ),
                        const SizedBox(width: 4),
                        // Menú popup para editar y eliminar
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: colors.hint, size: 18),
                          padding: EdgeInsets.zero,
                          onSelected: (val) {
                            if (val == 'editar') {
                              context.go('/catalogo/nuevo', extra: articulo);
                            } else if (val == 'eliminar') {
                              _eliminarArticulo(context, articulo.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: colors.primary), const SizedBox(width: 8), Text('Editar', style: font.bodySmall)])),
                            PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: colors.statusCritical), const SizedBox(width: 8), Text('Eliminar', style: font.bodySmall.copyWith(color: colors.statusCritical))])),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: font.caption,
                        children: [
                          const TextSpan(text: 'Stock: '),
                          TextSpan(
                            text: '${articulo.stockActual} ${articulo.unidad}',
                            style: TextStyle(color: config.colorPrincipal, fontWeight: FontWeight.w500),
                          ),
                          TextSpan(text: ' / mín. ${articulo.stockMinimo} ${articulo.unidad}'),
                        ],
                      ),
                    ),
                    Text(articulo.unidad, style: font.caption),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius.full),
                  child: LinearProgressIndicator(
                    value: ratio, minHeight: 4,
                    backgroundColor: colors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(config.colorPrincipal),
                  ),
                ),
              ],
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
        return _ConfigEstado(etiqueta: 'Crítico',
            colorPrincipal: colors.statusCritical, colorFondo: colors.dangerLight);
      case _EstadoStock.bajo:
        return _ConfigEstado(etiqueta: 'Bajo',
            colorPrincipal: colors.primary, colorFondo: colors.primaryLight);
      case _EstadoStock.normal:
        return _ConfigEstado(etiqueta: 'Normal',
            colorPrincipal: colors.statusNormal, colorFondo: colors.successLight);
    }
  }
}

enum _EstadoStock { critico, bajo, normal }

class _ConfigEstado {
  final String etiqueta;
  final Color colorPrincipal;
  final Color colorFondo;
  const _ConfigEstado({required this.etiqueta, required this.colorPrincipal, required this.colorFondo});
}
