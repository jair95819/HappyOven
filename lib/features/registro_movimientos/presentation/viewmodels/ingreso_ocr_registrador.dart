import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/repositories/i_articulos_repository.dart';
import 'package:happy_oven/core/repositories/i_movimientos_repository.dart';
import 'package:happy_oven/core/services/ocr_service.dart';

/// Ítem proveniente del escaneo OCR, ya editado/confirmado, listo para
/// registrarse como un movimiento de entrada.
class ItemOcrIngreso {
  final String nombre;
  final double cantidad;
  final String unidad;
  final double precioUnitario;

  const ItemOcrIngreso({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
  });
}

/// Resumen del resultado de registrar una boleta OCR completa.
class ResultadoIngresoOcr {
  /// Movimientos de entrada registrados con éxito (incluye los de insumos nuevos).
  final int exitosos;

  /// Insumos que no existían en el catálogo y se crearon durante el proceso.
  final int creados;

  /// Ítems que no se pudieron registrar por un error de base de datos.
  final int fallidos;

  const ResultadoIngresoOcr({
    required this.exitosos,
    required this.creados,
    required this.fallidos,
  });
}

/// Registra cada uno de los [items] como un movimiento de entrada.
///
/// Asocia el ítem al artículo del [catalogo] más parecido (tolera acentos,
/// mayúsculas y nombres parciales vía [OcrService.indiceMejorCoincidencia]); si
/// ninguno coincide, **crea un insumo nuevo** con los datos detectados en lugar
/// de descartar la línea — así una boleta con nombres que no calzan exactamente
/// con el catálogo igualmente se puede registrar.
///
/// No muta la lista [catalogo] recibida.
Future<ResultadoIngresoOcr> registrarIngresoOcr({
  required List<ItemOcrIngreso> items,
  required List<Articulo> catalogo,
  required String usuarioId,
  String? proveedor,
  required IArticulosRepository articulosRepository,
  required IMovimientosRepository movimientosRepository,
}) async {
  // Copia local: los insumos creados se agregan aquí para que líneas
  // posteriores con el mismo nombre los reconozcan y no se dupliquen dentro de
  // la misma boleta.
  final cat = List<Articulo>.of(catalogo);
  final nombres = cat.map((a) => a.nombre).toList();
  final proveedorLimpio = proveedor?.trim();

  int exitosos = 0;
  int creados = 0;
  int fallidos = 0;

  for (final item in items) {
    final idx = OcrService.indiceMejorCoincidencia(item.nombre, nombres);

    Articulo articulo;
    double nuevoStock;

    if (idx != null) {
      articulo = cat[idx];
      nuevoStock = articulo.stockActual + item.cantidad;
    } else {
      // El nombre no coincide con ningún insumo del catálogo: se crea uno nuevo
      // con los datos detectados. El stock arranca en 0 y el movimiento de
      // entrada lo deja en la cantidad ingresada.
      try {
        articulo = await articulosRepository.createArticulo(
          Articulo(
            id: '',
            nombre: item.nombre.trim(),
            tipo: 'insumo',
            unidad: item.unidad,
            stockActual: 0,
            stockMinimo: 0,
            precioUnitario: item.precioUnitario,
            activo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {
        fallidos++;
        continue;
      }
      cat.add(articulo);
      nombres.add(articulo.nombre);
      creados++;
      nuevoStock = item.cantidad;
    }

    try {
      await movimientosRepository.registrarMovimiento(
        Movimiento(
          id: '',
          articuloId: articulo.id,
          usuarioId: usuarioId,
          tipoMovimiento: 'entrada',
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          proveedor: (proveedorLimpio == null || proveedorLimpio.isEmpty)
              ? null
              : proveedorLimpio,
          porOcr: true,
          fecha: DateTime.now(),
        ),
      );

      await articulosRepository.updateArticulo(
        Articulo(
          id: articulo.id,
          nombre: articulo.nombre,
          categoriaId: articulo.categoriaId,
          tipo: articulo.tipo,
          unidad: articulo.unidad,
          stockActual: nuevoStock,
          stockMinimo: articulo.stockMinimo,
          precioUnitario: articulo.precioUnitario,
          activo: articulo.activo,
          createdAt: articulo.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      exitosos++;
    } catch (_) {
      fallidos++;
    }
  }

  return ResultadoIngresoOcr(
    exitosos: exitosos,
    creados: creados,
    fallidos: fallidos,
  );
}
