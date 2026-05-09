import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
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
    _searchController.addListener(() => setState(() => _query = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmarEliminar(Receta receta) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Estás seguro de que quieres eliminar "${receta.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final exito = await ref.read(recetasViewModelProvider.notifier).eliminarReceta(receta.id);
              if (exito && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('"${receta.nombre}" eliminada'),
                  backgroundColor: AppTheme.colorsOf(context).statusNormal,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Text('Eliminar', style: TextStyle(color: AppTheme.colorsOf(context).statusCritical)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    final recetasState = ref.watch(recetasViewModelProvider);
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(colors, font),
          Expanded(
            child: recetasState.when(
              data: (recetas) {
                final filtradas = recetas.where((r) =>
                    r.nombre.toLowerCase().contains(_query.toLowerCase())).toList();
                return _buildGrid(filtradas, colors, font);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error al cargar recetas')),
            ),
          ),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors, AppFont font) {
    final recetasState = ref.watch(recetasViewModelProvider);
    final count = recetasState.value?.length ?? 0;

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
                      Text('$count recetas registradas',
                          style: font.caption.copyWith(color: colors.accentDark)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/recetas/nueva'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: colors.titleText,
                        borderRadius: AppTheme.radius.brSm,
                      ),
                      child: Row(children: [
                        Icon(Icons.add_rounded, color: colors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text('Nueva', style: font.label.copyWith(
                          color: colors.accent, fontSize: 13)),
                      ]),
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
                  style: font.bodySmall.copyWith(fontSize: 13, color: colors.titleText),
                  decoration: InputDecoration(
                    hintText: 'Buscar receta...',
                    hintStyle: font.hint.copyWith(fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.hint, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Receta> recetas, AppColors colors, AppFont font) {
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
        child: recetas.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined, color: colors.hint, size: 48),
                    const SizedBox(height: 12),
                    Text(_query.isEmpty ? 'Aún no tienes recetas' : 'Sin resultados',
                        style: font.hint.copyWith(fontSize: 13)),
                    if (_query.isEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.push('/recetas/nueva'),
                        child: Text('Crear primera receta',
                            style: font.label.copyWith(fontSize: 13, color: colors.primary)),
                      ),
                    ],
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.88),
                itemCount: recetas.length,
                itemBuilder: (context, index) => _TarjetaReceta(
                  receta: recetas[index],
                  colors: colors,
                  font: font,
                  onEliminar: () => _confirmarEliminar(recetas[index]),
                ),
              ),
      ),
    );
  }
}

class _TarjetaReceta extends ConsumerWidget {
  final Receta receta;
  final AppColors colors;
  final AppFont font;
  final VoidCallback onEliminar;

  const _TarjetaReceta({
    required this.receta,
    required this.colors,
    required this.font,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buscar el artículo asociado para calcular costo
    final articulosState = ref.watch(catalogoViewModelProvider);
    final ingredientesState = ref.watch(ingredientesRecetaProvider(receta.id));

    double costoLote = 0;
    int numIngredientes = 0;

    ingredientesState.whenData((ingredientes) {
      numIngredientes = ingredientes.length;
      articulosState.whenData((articulos) {
        for (final ing in ingredientes) {
          try {
            final articulo = articulos.firstWhere((a) => a.id == ing.insumoId);
            costoLote += articulo.precioUnitario * ing.cantidadRequerida;
          } catch (_) {}
        }
      });
    });

    return GestureDetector(
      onTap: () => context.push('/recetas/editar', extra: receta),
      onLongPress: onEliminar,
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
              height: 80, width: double.infinity,
              color: colors.primaryLight,
              child: Stack(children: [
                Center(child: Icon(Icons.menu_book_outlined, color: colors.brownLight, size: 36)),
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.successLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.successBorder, width: 0.5),
                    ),
                    child: Text('\$${costoLote.toStringAsFixed(2)}',
                        style: font.label.copyWith(color: colors.statusNormal, fontSize: 11)),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receta.nombre,
                      style: font.label.copyWith(fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.inventory_2_outlined, color: colors.hint, size: 12),
                    const SizedBox(width: 4),
                    Text('$numIngredientes insumos', style: font.caption.copyWith(fontSize: 10)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.pie_chart_outline_rounded, color: colors.hint, size: 12),
                    const SizedBox(width: 4),
                    Text('Rinde: ${receta.rendimiento.toInt()} unid.',
                        style: font.caption.copyWith(fontSize: 10)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
