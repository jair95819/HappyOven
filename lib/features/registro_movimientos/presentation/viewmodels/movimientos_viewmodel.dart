import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/repositories/movimientos_repository.dart';
import 'package:happy_oven/core/repositories/articulos_repository.dart';
import 'package:happy_oven/core/providers.dart';

final movimientosViewModelProvider = StateNotifierProvider<MovimientosViewModel, AsyncValue<List<Movimiento>>>((ref) {
  return MovimientosViewModel(
    ref.watch(movimientosRepositoryProvider),
    ref.watch(articulosRepositoryProvider),
  );
});

class MovimientosViewModel extends StateNotifier<AsyncValue<List<Movimiento>>> {
  final MovimientosRepository _repository;
  final ArticulosRepository _articulosRepository;

  MovimientosViewModel(this._repository, this._articulosRepository) : super(const AsyncLoading()) {
    cargarMovimientos();
  }

  Future<void> cargarMovimientos() async {
    try {
      state = const AsyncLoading();
      final movimientos = await _repository.getHistorialMovimientos();
      state = AsyncData(movimientos);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> registrarMovimiento(Movimiento movimiento, Articulo articulo, double nuevoStock) async {
    try {
      // 1. Registrar movimiento
      await _repository.registrarMovimiento(movimiento);
      
      // 2. Actualizar stock del artículo
      final articuloActualizado = Articulo(
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
      );
      await _articulosRepository.updateArticulo(articuloActualizado);
      
      // 3. Recargar lista
      await cargarMovimientos();
      return true;
    } catch (e) {
      return false;
    }
  }
}
