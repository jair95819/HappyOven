import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/categoria.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/repositories/i_categorias_repository.dart';

/// Implementación de [ICategoriasRepository] utilizando la tabla `categorias` de Supabase.
class CategoriasRepository implements ICategoriasRepository {
  final SupabaseService _supabaseService;

  CategoriasRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  /// Realiza un select a Supabase para obtener todas las categorías, ordenadas por el campo `orden`.
  @override
  Future<List<Categoria>> getCategorias() async {
    final response = await _supabaseService.client
        .from('categorias')
        .select()
        .order('orden', ascending: true);

    return (response as List).map((json) => Categoria.fromJson(json)).toList();
  }

  @override
  Future<List<Categoria>> getCategoriasPorTipo(TipoArticulo tipo) async {
    final response = await _supabaseService.client
        .from('categorias')
        .select()
        .eq('tipo', tipo.dbValue)
        .order('orden', ascending: true);

    return (response as List).map((json) => Categoria.fromJson(json)).toList();
  }

  /// Inserta una nueva categoría en Supabase y omite el ID para usar el generado por la base de datos.
  @override
  Future<Categoria> createCategoria(Categoria categoria) async {
    final data = categoria.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('categorias')
        .insert(data)
        .select()
        .single();

    return Categoria.fromJson(response);
  }

  /// Actualiza un registro existente en la tabla `categorias` basándose en su ID.
  @override
  Future<Categoria> updateCategoria(Categoria categoria) async {
    final data = categoria.toJson();

    final response = await _supabaseService.client
        .from('categorias')
        .update(data)
        .eq('id', categoria.id)
        .select()
        .single();

    return Categoria.fromJson(response);
  }

  /// Elimina definitivamente el registro de categoría desde Supabase.
  @override
  Future<void> deleteCategoria(String id) async {
    await _supabaseService.client
        .from('categorias')
        .delete()
        .eq('id', id);
  }
}
