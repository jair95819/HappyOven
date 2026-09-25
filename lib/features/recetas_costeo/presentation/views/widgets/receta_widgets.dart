import 'package:flutter/material.dart';
import 'package:happy_oven/core/demo/diseno_demo.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/theme/theme.dart';

/// Colores de punto por ingrediente (tal cual el prototipo).
const coloresIngrediente = [
  Color(0xFF16A34A),
  Color(0xFFEAB308),
  Color(0xFF3B82F6),
  Color(0xFFF97316),
  Color(0xFFDC2626),
  Color(0xFFA16207),
  Color(0xFF64748B),
];

Articulo? articuloPorId(List<Articulo> articulos, String? id) {
  for (final a in articulos) {
    if (a.id == id) return a;
  }
  return null;
}

/// Costo total del lote a partir de los ingredientes y el precio de cada insumo.
double costoLote(List<RecetaIngrediente> ings, List<Articulo> articulos) {
  var total = 0.0;
  for (final ing in ings) {
    total += (articuloPorId(articulos, ing.insumoId)?.precioUnitario ?? 0) *
        ing.cantidadRequerida;
  }
  return total;
}

/// ID de foto para la receta (por nombre del producto o de la receta).
String? fotoReceta(Receta receta, Articulo? producto) =>
    DisenoDemo.fotoPara(producto?.nombre ?? '') ??
    DisenoDemo.fotoPara(receta.nombre);

String fmtNum(double v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

/// Tabla de ingredientes: Ingrediente · Cant. · C/unid · Total.
class IngredienteTable extends StatelessWidget {
  final List<RecetaIngrediente> ingredientes;
  final List<Articulo> articulos;

  const IngredienteTable({
    super.key,
    required this.ingredientes,
    required this.articulos,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    Widget th(String t, {bool end = false}) => Text(
      t.toUpperCase(),
      textAlign: end ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: c.bodyText,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('INGREDIENTES', style: AppTheme.fontOf(context).section),
        const SizedBox(height: 8),
        Container(
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
                    Expanded(flex: 16, child: th('Ingrediente')),
                    Expanded(flex: 7, child: th('Cant.', end: true)),
                    Expanded(flex: 9, child: th('C/unid', end: true)),
                    Expanded(flex: 8, child: th('Total', end: true)),
                  ],
                ),
              ),
              if (ingredientes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Sin ingredientes registrados',
                    style: TextStyle(fontSize: 12, color: c.hint),
                  ),
                ),
              for (var i = 0; i < ingredientes.length; i++)
                _fila(c, i, ingredientes[i]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fila(AppColors c, int i, RecetaIngrediente ing) {
    final art = articuloPorId(articulos, ing.insumoId);
    final precio = art?.precioUnitario ?? 0;
    final total = precio * ing.cantidadRequerida;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    color: coloresIngrediente[i % coloresIngrediente.length],
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
              '${fmtNum(ing.cantidadRequerida)} ${art?.unidad.dbValue ?? ''}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: c.bodyText),
            ),
          ),
          Expanded(
            flex: 9,
            child: Text(
              'S/ ${precio.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: c.bodyText),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              'S/ ${total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.titleText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
