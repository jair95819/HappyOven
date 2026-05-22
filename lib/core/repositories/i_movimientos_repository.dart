import 'package:happy_oven/core/models/movimiento.dart';

/// Interfaz para el manejo del registro histórico de los movimientos de inventario
/// (entradas y salidas de stock, compras, mermas, consumos, etc.).
abstract class IMovimientosRepository {
  /// Obtiene el historial completo de todos los movimientos registrados, usualmente ordenado por fecha descendente.
  Future<List<Movimiento>> getHistorialMovimientos();

  /// Obtiene los movimientos específicos asociados al [articuloId].
  Future<List<Movimiento>> getMovimientosPorArticulo(String articuloId);

  /// Registra un nuevo movimiento en la base de datos (y debe reflejarse en el stock del artículo).
  Future<Movimiento> registrarMovimiento(Movimiento movimiento);

  /// Elimina o anula un movimiento previamente registrado usando su [id].
  Future<void> deleteMovimiento(String id);
}