import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/categoria.dart';

class CategoriasRepository {
  final SupabaseService _supabaseService;

  CategoriasRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  Future<List<Categoria>> getCategorias() async {
    final response = await _supabaseService.client
        .from('categorias')
        .select()
        .order('orden', ascending: true);

    return (response as List).map((json) => Categoria.fromJson(json)).toList();
  }

  Future<List<Categoria>> getCategoriasPorTipo(String tipo) async {
    final response = await _supabaseService.client
        .from('categorias')
        .select()
        .eq('tipo', tipo)
        .order('orden', ascending: true);

    return (response as List).map((json) => Categoria.fromJson(json)).toList();
  }

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

  Future<void> deleteCategoria(String id) async {
    await _supabaseService.client
        .from('categorias')
        .delete()
        .eq('id', id);
  }
}
