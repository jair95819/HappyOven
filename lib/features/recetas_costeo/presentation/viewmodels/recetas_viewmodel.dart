import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/repositories/recetas_repository.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

// ── Provider del repositorio
final recetasRepositoryProvider = Provider<RecetasRepository>((ref) {
  return RecetasRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

// ── Provider del ViewModel (lista de recetas)
final recetasViewModelProvider =
    StateNotifierProvider<RecetasViewModel, AsyncValue<List<Receta>>>((ref) {
  return RecetasViewModel(ref.watch(recetasRepositoryProvider));
});

// ── Provider para ingredientes de una receta específica
final ingredientesRecetaProvider =
    FutureProvider.family<List<RecetaIngrediente>, String>((ref, recetaId) async {
  final repo = ref.watch(recetasRepositoryProvider);
  return repo.getIngredientesPorReceta(recetaId);
});

class RecetasViewModel extends StateNotifier<AsyncValue<List<Receta>>> {
  final RecetasRepository _repository;

  RecetasViewModel(this._repository) : super(const AsyncLoading()) {
    cargarRecetas();
  }

  Future<void> cargarRecetas() async {
    try {
      state = const AsyncLoading();
      final recetas = await _repository.getRecetas();
      state = AsyncData(recetas);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Crea una receta y sus ingredientes. Devuelve null si tiene éxito, o el error si falla.
  Future<String?> crearReceta(Receta receta, List<RecetaIngrediente> ingredientes) async {
    try {
      final nuevaReceta = await _repository.createReceta(receta);

      // Insertar ingredientes con el ID de la receta recién creada
      if (ingredientes.isNotEmpty) {
        final ingConRecetaId = ingredientes.map((i) => RecetaIngrediente(
          id: '',
          recetaId: nuevaReceta.id,
          insumoId: i.insumoId,
          cantidadRequerida: i.cantidadRequerida,
        )).toList();

        await _repository.reemplazarIngredientes(nuevaReceta.id, ingConRecetaId);
      }

      await cargarRecetas();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Actualiza una receta y reemplaza sus ingredientes.
  Future<String?> actualizarReceta(Receta receta, List<RecetaIngrediente> ingredientes) async {
    try {
      await _repository.updateReceta(receta);
      await _repository.reemplazarIngredientes(receta.id, ingredientes);
      await cargarRecetas();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> eliminarReceta(String id) async {
    try {
      await _repository.deleteReceta(id);
      await cargarRecetas();
      return true;
    } catch (e) {
      return false;
    }
  }
}
