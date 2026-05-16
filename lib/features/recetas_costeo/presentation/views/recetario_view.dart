import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class RecetarioView extends ConsumerStatefulWidget {
  const RecetarioView({super.key});

  @override
  ConsumerState<RecetarioView> createState() => _RecetarioViewState();
}

class _RecetarioViewState extends ConsumerState<RecetarioView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    final recetasState = ref.watch(recetasViewModelProvider);
    final articulosState = ref.watch(catalogoViewModelProvider);
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(colors, font, articulosState),
          Expanded(
            child: _buildContent(recetasState, articulosState, colors, font),
          ),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader(
    AppColors colors,
    AppFont font,
    AsyncValue<List<Articulo>> articulosState,
  ) {
    final productos =
        articulosState.valueOrNull
            ?.where((a) => a.tipo == 'producto_final')
            .length ??
        0;

    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recetario', style: font.h3),
                      const SizedBox(height: 2),
                      Text(
                        '$productos productos registrados',
                        style: font.caption.copyWith(color: colors.accentDark),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/recetas/nueva'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: colors.titleText,
                        borderRadius: AppTheme.radius.brSm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: colors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nueva',
                            style: font.label.copyWith(
                              color: colors.accent,
                              fontSize: 13,
                            ),
                          ),
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
                    fontSize: 13,
                    color: colors.titleText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: font.hint.copyWith(fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.hint,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<Receta>> recetasState,
    AsyncValue<List<Articulo>> articulosState,
    AppColors colors,
    AppFont font,
  ) {
    if (articulosState.isLoading || recetasState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final articulos = articulosState.valueOrNull ?? [];
    final recetas = recetasState.valueOrNull ?? [];
    final productos = articulos
        .where((a) => a.tipo == 'producto_final')
        .toList();

    final filtrados = productos
        .where((p) => p.nombre.toLowerCase().contains(_query.toLowerCase()))
        .toList();

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
        child: filtrados.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.breakfast_dining_outlined,
                      color: colors.hint,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _query.isEmpty
                          ? 'Aún no tienes productos'
                          : 'Sin resultados',
                      style: font.hint.copyWith(fontSize: 13),
                    ),
                    if (_query.isEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.push('/catalogo/nuevo'),
                        child: Text(
                          'Crear primer producto',
                          style: font.label.copyWith(
                            fontSize: 13,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                itemCount: filtrados.length,
                itemBuilder: (context, index) {
                  final pf = filtrados[index];
                  Receta? receta;
                  try {
                    receta = recetas.firstWhere((r) => r.productoId == pf.id);
                  } catch (_) {}
                  return _TarjetaProductoConReceta(
                    producto: pf,
                    receta: receta,
                    colors: colors,
                    font: font,
                  );
                },
              ),
      ),
    );
  }
}

class _TarjetaProductoConReceta extends ConsumerStatefulWidget {
  final Articulo producto;
  final Receta? receta;
  final AppColors colors;
  final AppFont font;

  const _TarjetaProductoConReceta({
    required this.producto,
    required this.receta,
    required this.colors,
    required this.font,
  });

  @override
  ConsumerState<_TarjetaProductoConReceta> createState() =>
      _TarjetaProductoConRecetaState();
}

class _TarjetaProductoConRecetaState
    extends ConsumerState<_TarjetaProductoConReceta> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final receta = widget.receta;
    final colors = widget.colors;
    final font = widget.font;
    final tieneReceta = receta != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 72,
              width: double.infinity,
              color: colors.primaryLight,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.breakfast_dining_outlined,
                      color: colors.brownLight,
                      size: 32,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: colors.hint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${producto.stockActual.toInt()} ${producto.unidad}',
                            style: font.caption.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tieneReceta)
                    Positioned(
                      top: 8,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.successLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.successBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          receta.nombre,
                          style: font.label.copyWith(
                            color: colors.statusNormal,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: font.label.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tieneReceta)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Rinde: ${receta.rendimiento.toInt()} unid.',
                            style: font.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (tieneReceta)
                    _buildRecetaSection(receta, colors, font)
                  else
                    _buildSinRecetaSection(colors, font, producto),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinRecetaSection(
    AppColors colors,
    AppFont font,
    Articulo producto,
  ) {
    return GestureDetector(
      onTap: () => context.push('/recetas/nueva', extra: producto),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: colors.primary, size: 14),
            const SizedBox(width: 6),
            Text(
              'Crear receta para este producto',
              style: font.label.copyWith(fontSize: 11, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecetaSection(Receta receta, AppColors colors, AppFont font) {
    final ingredientesAsync = ref.watch(ingredientesRecetaProvider(receta.id));
    final articulosAsync = ref.watch(catalogoViewModelProvider);
    final articulos = articulosAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: colors.hint, size: 12),
            const SizedBox(width: 4),
            ingredientesAsync.when(
              data: (ings) => Text(
                '${ings.length} ingredientes',
                style: font.caption.copyWith(fontSize: 10),
              ),
              loading: () => Text(
                'Cargando...',
                style: font.caption.copyWith(fontSize: 10),
              ),
              error: (_, __) =>
                  Text('Error', style: font.caption.copyWith(fontSize: 10)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _expandido = !_expandido),
              child: Row(
                children: [
                  Text(
                    _expandido ? 'Ocultar' : 'Ver detalle',
                    style: font.caption.copyWith(
                      fontSize: 10,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expandido
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
                                    '${ing.cantidadRequerida} ${insumo?.unidad ?? ''}',
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
                  error: (_, __) => Padding(
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
