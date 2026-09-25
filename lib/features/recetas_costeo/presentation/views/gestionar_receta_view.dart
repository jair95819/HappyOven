import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:happy_oven/core/demo/diseno_demo.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/configuracion/presentation/views/gestion_categorias_view.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/widgets/receta_widgets.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

/// Gestión de una receta (diseño "Gestionar recetas").
///
/// TODO: pestañas Favoritas / Categorías / Historial, etiquetas y compartir
/// son visuales; falta su lógica.
class GestionarRecetaView extends ConsumerStatefulWidget {
  final Receta receta;

  const GestionarRecetaView({super.key, required this.receta});

  @override
  ConsumerState<GestionarRecetaView> createState() =>
      _GestionarRecetaViewState();
}

class _GestionarRecetaViewState extends ConsumerState<GestionarRecetaView> {
  int _tab = 0;

  static const _tabs = ['Mis recetas', 'Favoritas', 'Categorías', 'Historial'];
  static const _iconos = [
    Icons.menu_book_outlined,
    Icons.star_border_rounded,
    Icons.folder_outlined,
    Icons.schedule_rounded,
  ];

  void _proximamente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final receta = widget.receta;
    final articulos = ref.watch(catalogoViewModelProvider).valueOrNull ?? [];
    final ingredientes =
        ref.watch(ingredientesRecetaProvider(receta.id)).valueOrNull ?? [];
    final categorias = ref.watch(categoriasViewModelProvider).valueOrNull ?? [];
    final producto = articuloPorId(articulos, receta.productoId);
    String categoria = 'Sin categoría';
    for (final cat in categorias) {
      if (cat.id == producto?.categoriaId) categoria = cat.nombre;
    }
    final total = ingredientes.isEmpty
        ? receta.costoLote
        : costoLote(ingredientes, articulos);
    final porcion = receta.rendimiento > 0 ? total / receta.rendimiento : 0.0;
    final precio = producto?.precioUnitario ?? 0;
    final pctCosto = precio > 0 ? '${(porcion / precio * 100).toStringAsFixed(1)}%' : '--';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: HoTopBar(
        title: 'Gestionar recetas',
        subtitle: 'Crea y administra tus recetas',
        onBack: () => context.pop(),
        actions: [
          Material(
            color: c.statusNormal,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/recetas/nueva'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: c.white),
                    const SizedBox(width: 6),
                    Text(
                      'Nueva',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: HoUnderlineTabs(
          labels: _tabs,
          icons: _iconos,
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HoCard(
              radius: 16,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  HoPhoto(
                    photoId: fotoReceta(receta, producto),
                    width: 64,
                    height: 64,
                    px: 128,
                    radius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                        const SizedBox(height: 2),
                        HoBadge(
                          text: categoria,
                          color: c.primaryDark,
                          background: c.primaryLight,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rinde: ${fmtNum(receta.rendimiento)} porciones · Últ. act. ${DateFormat('dd/MM/yyyy').format(receta.updatedAt)}',
                          style: TextStyle(fontSize: 11, color: c.bodyText),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Costo total',
                        style: TextStyle(fontSize: 10, color: c.bodyText),
                      ),
                      Text(
                        'S/ ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.titleText,
                        ),
                      ),
                      Text(
                        'S/ ${porcion.toStringAsFixed(2)} / porción',
                        style: TextStyle(fontSize: 10, color: c.bodyText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HoSectionLabel(
              'Ingredientes',
              trailing: GestureDetector(
                onTap: () => context.push('/recetas/editar', extra: receta),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: c.statusNormal),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar ingrediente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.statusNormal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _tablaIngredientes(c, ingredientes, articulos, receta),
            const SizedBox(height: 16),
            const HoSectionLabel('Resumen de costos'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: HoCostCard(
                    label: 'Costo total',
                    value: 'S/ ${total.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HoCostCard(
                    label: 'Costo por porción',
                    value: 'S/ ${porcion.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HoCostCard(label: '% Costo ingred.', value: pctCosto),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HoLabeledField(
                    label: 'Categoría',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: c.primaryLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 18, color: c.bodyText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoria,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: c.titleText),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: c.bodyText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HoLabeledField(
                    label: 'Etiquetas',
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.primaryLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in DisenoDemo.etiquetas)
                            HoBadge(
                              text: e,
                              color: c.successDeep,
                              background: c.successLight,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _accion(
                    c,
                    Icons.save_outlined,
                    'Guardar',
                    () => context.pop(),
                    principal: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _accion(
                    c,
                    Icons.visibility_outlined,
                    'Vista previa',
                    () => context.push('/recetas/ver', extra: receta),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _accion(
                    c,
                    Icons.share_outlined,
                    'Compartir',
                    _proximamente,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tablaIngredientes(
    AppColors c,
    List<RecetaIngrediente> ingredientes,
    List<Articulo> articulos,
    Receta receta,
  ) {
    Widget th(String t, {bool end = false}) => Text(
      t.toUpperCase(),
      textAlign: end ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: c.bodyText,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: c.bg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 16, child: th('Insumo')),
                Expanded(flex: 7, child: th('Cant.', end: true)),
                const SizedBox(width: 8),
                Expanded(flex: 6, child: th('Unid.')),
                Expanded(flex: 7, child: th('Costo', end: true)),
                const SizedBox(width: 28),
              ],
            ),
          ),
          for (var i = 0; i < ingredientes.length; i++)
            Builder(
              builder: (_) {
                final ing = ingredientes[i];
                final art = articuloPorId(articulos, ing.insumoId);
                final costo = (art?.precioUnitario ?? 0) * ing.cantidadRequerida;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: coloresIngrediente[
                                    i % coloresIngrediente.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                art?.nombre ?? '---',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: c.titleText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          fmtNum(ing.cantidadRequerida),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: c.bodyText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: Text(
                          art?.unidad.dbValue ?? '',
                          style: TextStyle(fontSize: 12, color: c.bodyText),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          'S/ ${costo.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.titleText,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: Icon(Icons.more_vert_rounded, color: c.bodyText),
                          onPressed: () =>
                              context.push('/recetas/editar', extra: receta),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _accion(
    AppColors c,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool principal = false,
  }) {
    return Material(
      color: principal ? c.statusNormal : c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: principal ? null : Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: principal ? c.white : c.titleText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: principal ? c.white : c.titleText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
