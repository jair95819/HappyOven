import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/repositories/i_articulos_repository.dart';

/// Implementación concreta de [IArticulosRepository] comunicándose con la tabla `articulos` de Supabase.
class ArticulosRepository implements IArticulosRepository {
  final SupabaseService _supabaseService;

  ArticulosRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  /// Realiza un select a Supabase sin filtros para obtener el listado completo de artículos.
  @override
  Future<List<Articulo>> getArticulos() async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .order('nombre', ascending: true);

    return (response as List).map((json) => Articulo.fromJson(json)).toList();
  }

  @override
  Future<List<Articulo>> getInsumos() async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .eq('tipo', TipoArticulo.insumo.dbValue)
        .order('nombre', ascending: true);

    return (response as List).map((json) => Articulo.fromJson(json)).toList();
  }

  @override
  Future<List<Articulo>> getProductosFinales() async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .eq('tipo', TipoArticulo.productoFinal.dbValue)
        .order('nombre', ascending: true);

    return (response as List).map((json) => Articulo.fromJson(json)).toList();
  }

  /// Busca en Supabase un registro puntual comparando la columna `id`.
  @override
  Future<Articulo?> getArticuloById(String id) async {
    final response = await _supabaseService.client
        .from('articulos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Articulo.fromJson(response);
  }

  /// Inserta un nuevo registro en la tabla `articulos` de Supabase, dejando que la BD asigne el ID.
  @override
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

  /// Actualiza en Supabase el registro correspondiente, refrescando la columna `updated_at`.
  @override
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

  /// Elimina el registro por completo de Supabase usando el método `delete()`.
  @override
  Future<void> deleteArticulo(String id) async {
    // Si prefieres soft-delete, podrías hacer un update a activo = false
    await _supabaseService.client
        .from('articulos')
        .delete()
        .eq('id', id);
  }
}
