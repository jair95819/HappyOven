import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/repositories/movimientos_repository.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

final movimientosRepositoryProvider = Provider<MovimientosRepository>((ref) {
  return MovimientosRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final movimientosViewModelProvider = StateNotifierProvider<MovimientosViewModel, AsyncValue<List<Movimiento>>>((ref) {
  return MovimientosViewModel(
    ref.watch(movimientosRepositoryProvider),
    ref.read(catalogoViewModelProvider.notifier),
  );
});

class MovimientosViewModel extends StateNotifier<AsyncValue<List<Movimiento>>> {
  final MovimientosRepository _repository;
  final CatalogoViewModel _catalogoViewModel;

  MovimientosViewModel(this._repository, this._catalogoViewModel) : super(const AsyncLoading()) {
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
      await _catalogoViewModel.guardarArticulo(articuloActualizado);
      
      // 3. Recargar lista
      await cargarMovimientos();
      return true;
    } catch (e) {
      return false;
    }
  }
}
