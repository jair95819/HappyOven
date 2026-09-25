import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/widgets/receta_widgets.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

/// Análisis de costos y rentabilidad de una receta (diseño "Analizar costos").
class AnalizarCostosView extends ConsumerStatefulWidget {
  final Receta? receta;

  const AnalizarCostosView({super.key, this.receta});

  @override
  ConsumerState<AnalizarCostosView> createState() => _AnalizarCostosViewState();
}

class _AnalizarCostosViewState extends ConsumerState<AnalizarCostosView> {
  Receta? _receta;
  final _precioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _receta = widget.receta;
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  void _elegirReceta(List<Receta> recetas) {
    final c = AppTheme.colorsOf(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Seleccionar receta',
              style: AppTheme.serif(
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.titleText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final r in recetas)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.nombre),
                subtitle: Text('Rinde: ${fmtNum(r.rendimiento)}'),
                trailing: r.id == _receta?.id
                    ? Icon(Icons.check_rounded, color: c.statusNormal)
                    : null,
                onTap: () {
                  setState(() {
                    _receta = r;
                    _precioController.clear();
                  });
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final recetas = ref.watch(recetasViewModelProvider).valueOrNull ?? [];
    final articulos = ref.watch(catalogoViewModelProvider).valueOrNull ?? [];
    final receta = _receta ?? (recetas.isNotEmpty ? recetas.first : null);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: HoTopBar(
        title: 'Analizar costos',
        subtitle: 'Detalle de costos por producto',
        onBack: () => context.pop(),
      ),
      body: receta == null
          ? Center(
              child: Text(
                'No hay recetas registradas',
                style: TextStyle(color: c.bodyText),
              ),
            )
          : _buildContenido(c, receta, recetas, articulos),
    );
  }

  Widget _buildContenido(
    AppColors c,
    Receta receta,
    List<Receta> recetas,
    List<Articulo> articulos,
  ) {
    final ingredientes =
        ref.watch(ingredientesRecetaProvider(receta.id)).valueOrNull ?? [];
    final producto = articuloPorId(articulos, receta.productoId);
    final total = ingredientes.isEmpty
        ? receta.costoLote
        : costoLote(ingredientes, articulos);
    final unitario = receta.rendimiento > 0 ? total / receta.rendimiento : 0.0;
    if (_precioController.text.isEmpty && (producto?.precioUnitario ?? 0) > 0) {
      _precioController.text = producto!.precioUnitario.toStringAsFixed(2);
    }
    final precio = double.tryParse(_precioController.text) ?? 0;
    final ganancia = precio - unitario;
    final margen = precio > 0 ? ganancia / precio * 100 : 0.0;
    final saludable = margen >= 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HoCard(
            radius: 16,
            padding: const EdgeInsets.all(12),
            onTap: () => _elegirReceta(recetas),
            child: Row(
              children: [
                HoPhoto(
                  photoId: fotoReceta(receta, producto),
                  width: 56,
                  height: 56,
                  px: 112,
                  radius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receta.nombre,
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
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: c.bodyText),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const HoSectionLabel('Resumen de costos'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: HoCostCard(
                  label: 'Costo total de la receta',
                  value: 'S/ ${total.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoCostCard(
                  label: 'Costo por unidad (producción)',
                  value: 'S/ ${unitario.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IngredienteTable(
            ingredientes: ingredientes,
            articulos: articulos,
          ),
          const SizedBox(height: 20),
          const HoSectionLabel('Análisis de rentabilidad'),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio venta / u',
                          style: TextStyle(fontSize: 10, color: c.bodyText),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'S/',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.bodyText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _precioController,
                                  onChanged: (_) => setState(() {}),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.titleText,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: '0.00',
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tileVerde(
                    c,
                    'Ganancia / u',
                    'S/ ${ganancia.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tileVerde(
                    c,
                    'Margen',
                    '${margen.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Margen de ganancia = (Ganancia / Precio de venta) × 100',
            style: TextStyle(fontSize: 11, color: c.bodyText),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendación',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        saludable
                            ? 'Tu margen de ganancia es saludable. Puedes mantener el precio actual o evaluar estrategias de marketing para aumentar las ventas.'
                            : 'Tu margen de ganancia es bajo. Evalúa subir el precio de venta o reducir el costo de los insumos.',
                        style: TextStyle(fontSize: 13, color: c.bodyText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileVerde(AppColors c, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.successLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: c.bodyText)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.successDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
