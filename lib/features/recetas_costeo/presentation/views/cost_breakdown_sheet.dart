import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';

class CostBreakdownSheet extends ConsumerWidget {
  final String recetaId;
  const CostBreakdownSheet({super.key, required this.recetaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientesAsync = ref.watch(ingredientesRecetaProvider(recetaId));
    final articulosAsync = ref.watch(catalogoViewModelProvider);
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ingredientesAsync.when(
        data: (ings) {
          final articulos = articulosAsync.valueOrNull ?? [];
          double total = 0;
          final rows = ings.map((ing) {
            final art = articulos.firstWhere(
              (a) => a.id == ing.insumoId,
              orElse: () => Articulo(
                id: '',
                nombre: '---',
                categoriaId: null,
                tipo: 'insumo',
                unidad: '',
                stockActual: 0,
                stockMinimo: 0,
                precioUnitario: 0,
                activo: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            final costo = (art.precioUnitario) * ing.cantidadRequerida;
            total += costo;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(art.nombre, style: font.bodySmall),
              subtitle: Text('${ing.cantidadRequerida} ${art.unidad}', style: font.caption),
              trailing: Text('S/ ${costo.toStringAsFixed(2)}', style: font.label),
            );
          }).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(height: 4, width: 40, color: colors.surface)),
              const SizedBox(height: 12),
              Text('Desglose de costos', style: font.h3),
              const SizedBox(height: 8),
              ...rows,
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Costo Total del Lote:', style: font.label.copyWith(fontWeight: FontWeight.w600)),
                    Text('S/ ${total.toStringAsFixed(2)}', style: font.h3),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
        loading: () => SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: colors.primary))),
        error: (_, __) => SizedBox(height: 120, child: Center(child: Text('Error al cargar desglose', style: font.caption.copyWith(color: colors.statusCritical)))),
      ),
    );
  }
}
