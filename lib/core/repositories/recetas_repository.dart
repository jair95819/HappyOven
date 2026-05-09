import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';

class RecetasRepository {
  final SupabaseService _supabaseService;

  RecetasRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Obtener todas las recetas
  Future<List<Receta>> getRecetas() async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .order('nombre', ascending: true);

    return (response as List).map((json) => Receta.fromJson(json)).toList();
  }

  // Obtener una receta por ID
  Future<Receta?> getRecetaById(String id) async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Receta.fromJson(response);
  }

  // Crear una receta
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

  // Obtener ingredientes de una receta
  Future<List<RecetaIngrediente>> getIngredientesPorReceta(String recetaId) async {
    final response = await _supabaseService.client
        .from('receta_ingredientes')
        .select()
        .eq('receta_id', recetaId);

    return (response as List)
        .map((json) => RecetaIngrediente.fromJson(json))
        .toList();
  }

  // Agregar ingrediente a una receta
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

  // Eliminar receta
  Future<void> deleteReceta(String id) async {
    await _supabaseService.client
        .from('recetas')
        .delete()
        .eq('id', id);
  }
}
