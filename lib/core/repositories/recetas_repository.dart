import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';

class RecetasRepository {
  final SupabaseService _supabaseService;

  RecetasRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // ── RECETAS ────────────────────────────────────────────

  Future<List<Receta>> getRecetas() async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .order('nombre', ascending: true);

    return (response as List).map((json) => Receta.fromJson(json)).toList();
  }

  Future<Receta?> getRecetaById(String id) async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Receta.fromJson(response);
  }

  Future<Receta> createReceta(Receta receta) async {
    final data = receta.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('recetas')
        .insert(data)
        .select()
        .single();

    return Receta.fromJson(response);
  }

  Future<Receta> updateReceta(Receta receta) async {
    final data = receta.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('recetas')
        .update(data)
        .eq('id', receta.id)
        .select()
        .single();

    return Receta.fromJson(response);
  }

  Future<void> deleteReceta(String id) async {
    // Los ingredientes se eliminan en cascada por la FK
    await _supabaseService.client
        .from('recetas')
        .delete()
        .eq('id', id);
  }

  // ── INGREDIENTES DE RECETA ─────────────────────────────

  Future<List<RecetaIngrediente>> getIngredientesPorReceta(String recetaId) async {
    final response = await _supabaseService.client
        .from('receta_ingredientes')
        .select()
        .eq('receta_id', recetaId);

    return (response as List)
        .map((json) => RecetaIngrediente.fromJson(json))
        .toList();
  }

  Future<RecetaIngrediente> addIngrediente(RecetaIngrediente ingrediente) async {
    final data = ingrediente.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('receta_ingredientes')
        .insert(data)
        .select()
        .single();

    return RecetaIngrediente.fromJson(response);
  }

  Future<void> deleteIngrediente(String id) async {
    await _supabaseService.client
        .from('receta_ingredientes')
        .delete()
        .eq('id', id);
  }

  /// Reemplaza todos los ingredientes de una receta de golpe.
  /// Útil al editar una receta completa.
  Future<List<RecetaIngrediente>> reemplazarIngredientes(
      String recetaId, List<RecetaIngrediente> ingredientes) async {
    // 1. Borrar los existentes
    await _supabaseService.client
        .from('receta_ingredientes')
        .delete()
        .eq('receta_id', recetaId);

    // 2. Insertar los nuevos
    if (ingredientes.isEmpty) return [];

    final datos = ingredientes.map((i) {
      final d = i.toJson();
      d.remove('id');
      d['receta_id'] = recetaId;
      return d;
    }).toList();

    final response = await _supabaseService.client
        .from('receta_ingredientes')
        .insert(datos)
        .select();

    return (response as List)
        .map((json) => RecetaIngrediente.fromJson(json))
        .toList();
  }
}
