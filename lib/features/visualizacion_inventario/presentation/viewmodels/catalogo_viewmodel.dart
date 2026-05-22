import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/repositories/articulos_repository.dart';
import 'package:happy_oven/core/providers.dart';

final catalogoViewModelProvider = StateNotifierProvider<CatalogoViewModel, AsyncValue<List<Articulo>>>((ref) {
  return CatalogoViewModel(ref.watch(articulosRepositoryProvider));
});

class CatalogoViewModel extends StateNotifier<AsyncValue<List<Articulo>>> {
  final ArticulosRepository _repository;

  CatalogoViewModel(this._repository) : super(const AsyncLoading()) {
    cargarArticulos();
  }

  Future<void> cargarArticulos() async {
    try {
      state = const AsyncLoading();
      final articulos = await _repository.getArticulos();
      state = AsyncData(articulos);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> guardarArticulo(Articulo articulo) async {
    try {
      if (articulo.id.isEmpty) {
        await _repository.createArticulo(articulo);
      } else {
        await _repository.updateArticulo(articulo);
      }
      await cargarArticulos(); // Recargar la lista
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> eliminarArticulo(String id) async {
    try {
      await _repository.deleteArticulo(id);
      await cargarArticulos(); // Recargar la lista
      return true;
    } catch (e) {
      return false;
    }
  }
}
