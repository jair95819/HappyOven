import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/articulo.dart';

class ArticulosRepository {
  final SupabaseService _supabaseService;

  ArticulosRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Obtener todos los artículos (insumos y productos finales)
  Future<List<Articulo>> getArticulos() async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .order('nombre', ascending: true);

    return (response as List).map((json) => Articulo.fromJson(json)).toList();
  }

  // Obtener solo insumos
  Future<List<Articulo>> getInsumos() async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .eq('tipo', 'insumo')
        .order('nombre', ascending: true);

    return (response as List).map((json) => Articulo.fromJson(json)).toList();
  }

  // Obtener solo productos finales
  Future<List<Articulo>> getProductosFinales() async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .eq('tipo', 'producto_final')
        .order('nombre', ascending: true);

    return (response as List).map((json) => Articulo.fromJson(json)).toList();
  }

  // Obtener un artículo por ID
  Future<Articulo?> getArticuloById(String id) async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Articulo.fromJson(response);
  }

  // Crear un nuevo artículo
  Future<Articulo> createArticulo(Articulo articulo) async {
    final data = articulo.toJson();
    data.remove('id'); // Dejar que la BD genere el ID

    final response = await _supabaseService.client
        .from('articulos')
        .insert(data)
        .select()
        .single();

    return Articulo.fromJson(response);
  }

  // Actualizar un artículo existente
  Future<Articulo> updateArticulo(Articulo articulo) async {
    final data = articulo.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabaseService.client
        .from('articulos')
        .update(data)
        .eq('id', articulo.id)
        .select()
        .single();

    return Articulo.fromJson(response);
  }

  // Eliminar (o desactivar) un artículo
  Future<void> deleteArticulo(String id) async {
    // Si prefieres soft-delete, podrías hacer un update a activo = false
    await _supabaseService.client
        .from('articulos')
        .delete()
        .eq('id', id);
  }
}
