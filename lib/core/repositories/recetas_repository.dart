import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/repositories/i_recetas_repository.dart';

/// Implementación de [IRecetasRepository] que maneja tanto la tabla maestra `recetas`
/// como la tabla de detalle `receta_ingredientes` en Supabase.
class RecetasRepository implements IRecetasRepository {
  final SupabaseService _supabaseService;

  RecetasRepository({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  // ── RECETAS ────────────────────────────────────────────

  /// Obtiene la lista completa de recetas maestras ordenadas alfabéticamente.
  @override
  Future<List<Receta>> getRecetas() async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .order('nombre', ascending: true);

    return (response as List).map((json) => Receta.fromJson(json)).toList();
  }

  /// Consulta una única receta por su ID. Retorna null si no existe el registro.
  @override
  Future<Receta?> getRecetaById(String id) async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Receta.fromJson(response);
  }

  /// Consulta la receta maestra vinculada directamente al [productoId].
  @override
  Future<Receta?> getRecetaByProductoId(String productoId) async {
    final response = await _supabaseService.client
        .from('recetas')
        .select()
        .eq('producto_id', productoId)
        .maybeSingle();

    if (response == null) return null;
    return Receta.fromJson(response);
  }

  /// Inserta el maestro de la receta en Supabase omitiendo el ID para que se genere automáticamente.
  @override
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

  /// Actualiza los datos de la receta maestra (rendimiento, costos de preparación, etc.).
  @override
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

  /// Elimina la receta maestra de Supabase. (Los ingredientes deberían eliminarse en cascada a nivel de BD).
  @override
  Future<void> deleteReceta(String id) async {
    await _supabaseService.client.from('recetas').delete().eq('id', id);
  }

  /// Obtiene de la tabla `receta_ingredientes` el desglose de insumos requeridos por una receta.
  @override
  Future<List<RecetaIngrediente>> getIngredientesPorReceta(
    String recetaId,
  ) async {
    final response = await _supabaseService.client
        .from('receta_ingredientes')
        .select()
        .eq('receta_id', recetaId);

    return (response as List)
        .map((json) => RecetaIngrediente.fromJson(json))
        .toList();
  }

  /// Agrega un solo insumo a una receta existente.
  @override
  Future<RecetaIngrediente> addIngrediente(
    RecetaIngrediente ingrediente,
  ) async {
    final data = ingrediente.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('receta_ingredientes')
        .insert(data)
        .select()
        .single();

    return RecetaIngrediente.fromJson(response);
  }

  /// Elimina un insumo específico de una receta en particular por su ID de relación.
  @override
  Future<void> deleteIngrediente(String id) async {
    await _supabaseService.client
        .from('receta_ingredientes')
        .delete()
        .eq('id', id);
  }

  /// Reemplaza todos los ingredientes de la receta indicada realizando una transacción lógica:
  /// borra primero los existentes y luego inserta en bloque la nueva lista de [ingredientes].
  @override
  Future<List<RecetaIngrediente>> reemplazarIngredientes(
    String recetaId,
    List<RecetaIngrediente> ingredientes,
  ) async {
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
