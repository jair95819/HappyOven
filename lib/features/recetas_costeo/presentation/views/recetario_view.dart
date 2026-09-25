import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/widgets/receta_widgets.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class RecetarioView extends ConsumerStatefulWidget {
  const RecetarioView({super.key});

  @override
  ConsumerState<RecetarioView> createState() => _RecetarioViewState();
}

class _RecetarioViewState extends ConsumerState<RecetarioView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _tab = 0;
  int _pagina = 1;

  static const _tabs = ['Todas', 'Mis recetas', 'Archivadas'];
  static const _porPagina = 5;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() {
        _query = _searchController.text;
        _pagina = 1;
      }),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recetasState = ref.watch(recetasViewModelProvider);
    final articulos = ref.watch(catalogoViewModelProvider).valueOrNull ?? [];
    final c = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          HoHeader(
            title: 'Recetario',
            subtitle: 'Gestiona las recetas de tus productos',
            action: HoHeaderButton(
              label: 'Nueva receta',
              icon: Icons.add_rounded,
              onTap: () => context.push('/recetas/nueva'),
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HoSearchField(
                  controller: _searchController,
                  hint: 'Buscar receta por nombre...',
                ),
                const SizedBox(height: 12),
                HoUnderlineTabs(
                  labels: _tabs,
                  selected: _tab,
                  onChanged: (i) => setState(() {
                    _tab = i;
                    _pagina = 1;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: recetasState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (recetas) => _buildLista(c, recetas, articulos),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(
    AppColors c,
    List<Receta> recetas,
    List<Articulo> articulos,
  ) {
    final q = _query.toLowerCase();
    // TODO: "Mis recetas" (por autor) y "Archivadas" requieren datos en BD.
    final filtradas = _tab == 2
        ? <Receta>[]
        : recetas.where((r) => r.nombre.toLowerCase().contains(q)).toList();
    final totalPaginas = (filtradas.length / _porPagina).ceil().clamp(1, 9999);
    final pagina = _pagina.clamp(1, totalPaginas);
    final visibles = filtradas
        .skip((pagina - 1) * _porPagina)
        .take(_porPagina)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recetasViewModelProvider);
        await ref.read(catalogoViewModelProvider.notifier).cargarArticulos();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (visibles.isEmpty) ...[
            const SizedBox(height: 48),
            Icon(Icons.menu_book_outlined, size: 40, color: c.hint),
            const SizedBox(height: 8),
            Text(
              'No se encontraron recetas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.bodyText,
              ),
            ),
            Text(
              'Intenta buscar con otros términos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.hint),
            ),
          ],
          for (final r in visibles) ...[
            _TarjetaReceta(receta: r, articulos: articulos),
            const SizedBox(height: 12),
          ],
          if (filtradas.isNotEmpty) _paginacion(c, pagina, totalPaginas),
        ],
      ),
    );
  }

  Widget _paginacion(AppColors c, int pagina, int total) {
    Widget boton(
      String label,
      IconData icon,
      bool enabled,
      VoidCallback onTap, {
      bool iconFirst = true,
    }) {
      return Opacity(
        opacity: enabled ? 1 : 0.3,
        child: Material(
          color: c.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  if (iconFirst) Icon(icon, size: 16, color: c.titleText),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.titleText,
                    ),
                  ),
                  if (!iconFirst) Icon(icon, size: 16, color: c.titleText),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return HoCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          boton(
            'Anterior',
            Icons.chevron_left_rounded,
            pagina > 1,
            () => setState(() => _pagina = pagina - 1),
          ),
          Text.rich(
            TextSpan(
              text: 'Página ',
              children: [
                TextSpan(
                  text: '$pagina',
                  style: TextStyle(color: c.titleText),
                ),
                TextSpan(text: ' de $total'),
              ],
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.bodyText,
            ),
          ),
          boton(
            'Siguiente',
            Icons.chevron_right_rounded,
            pagina < total,
            () => setState(() => _pagina = pagina + 1),
            iconFirst: false,
          ),
        ],
      ),
    );
  }
}

class _TarjetaReceta extends ConsumerWidget {
  final Receta receta;
  final List<Articulo> articulos;

  const _TarjetaReceta({required this.receta, required this.articulos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.colorsOf(context);
    final producto = articuloPorId(articulos, receta.productoId);
    final ingredientes = ref
        .watch(ingredientesRecetaProvider(receta.id))
        .valueOrNull;
    final total = ingredientes == null || ingredientes.isEmpty
        ? receta.costoLote
        : costoLote(ingredientes, articulos);
    final unitario = receta.rendimiento > 0 ? total / receta.rendimiento : 0.0;
    void ver() => context.push('/recetas/ver', extra: receta);

    return HoCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: ver,
                child: HoPhoto(
                  photoId: fotoReceta(receta, producto),
                  width: 64,
                  height: 64,
                  px: 128,
                  radius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: ver,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receta.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.titleText,
                        ),
                      ),
                      Text(
                        'Rinde: ${fmtNum(receta.rendimiento)} ${producto?.unidad.dbValue ?? 'unidades'}',
                        style: TextStyle(fontSize: 12, color: c.bodyText),
                      ),
                      Text(
                        'Actualizada: ${DateFormat('dd/MM/yyyy').format(receta.updatedAt)}',
                        style: TextStyle(fontSize: 12, color: c.bodyText),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: c.bodyText,
                    size: 20,
                  ),
                  color: c.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    switch (v) {
                      case 'editar':
                        context.push('/recetas/gestionar', extra: receta);
                      case 'eliminar':
                        _confirmarEliminar(context, ref, c);
                      default:
                        // TODO: duplicar / archivar.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                    }
                  },
                  itemBuilder: (_) => [
                    _item(c, 'editar', Icons.edit_outlined, 'Editar'),
                    _item(c, 'duplicar', Icons.copy_rounded, 'Duplicar'),
                    _item(c, 'archivar', Icons.folder_outlined, 'Archivar'),
                    _item(
                      c,
                      'eliminar',
                      Icons.delete_outline_rounded,
                      'Eliminar',
                      danger: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stat(
                  c,
                  'Costo total',
                  'S/ ${total.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  c,
                  'Costo por unidad',
                  'S/ ${unitario.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(AppColors c, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: c.bodyText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: c.titleText,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _item(
    AppColors c,
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? c.statusCritical : c.titleText;
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

  void _confirmarEliminar(BuildContext context, WidgetRef ref, AppColors c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar receta?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Se eliminará "${receta.nombre}" y todos sus ingredientes. Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 13, color: c.bodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: c.bodyText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(recetasViewModelProvider.notifier)
                  .eliminarReceta(receta.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Receta eliminada' : 'Error al eliminar la receta',
                  ),
                  backgroundColor: ok ? c.statusNormal : c.statusCritical,
                ),
              );
            },
            child: Text(
              'Eliminar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: c.statusCritical,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
