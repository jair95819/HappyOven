import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/core/repositories/i_ordenes_produccion_repository.dart';

class OrdenesProduccionRepository implements IOrdenesProduccionRepository {
  final SupabaseService _supabaseService;

  OrdenesProduccionRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  @override
  Future<List<OrdenProduccion>> getOrdenes() async {
    final response = await _supabaseService.client
        .from('ordenes_produccion')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => OrdenProduccion.fromJson(json)).toList();
  }

  @override
  Future<List<OrdenProduccion>> getOrdenesPorEstado(String estado) async {
    final response = await _supabaseService.client
        .from('ordenes_produccion')
        .select()
        .eq('estado', estado)
        .order('created_at', ascending: false);

    return (response as List).map((json) => OrdenProduccion.fromJson(json)).toList();
  }

  @override
  Future<OrdenProduccion?> getOrdenById(String id) async {
    final response = await _supabaseService.client
        .from('ordenes_produccion')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return OrdenProduccion.fromJson(response);
  }

  @override
  Future<OrdenProduccion> createOrden(OrdenProduccion orden) async {
    final data = orden.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('ordenes_produccion')
        .insert(data)
        .select()
        .single();

    return OrdenProduccion.fromJson(response);
  }

  @override
  Future<OrdenProduccion> updateOrden(OrdenProduccion orden) async {
    final data = orden.toJson();
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabaseService.client
        .from('ordenes_produccion')
        .update(data)
        .eq('id', orden.id)
        .select()
        .single();

    return OrdenProduccion.fromJson(response);
  }

  @override
  Future<void> deleteOrden(String id) async {
    await _supabaseService.client
        .from('ordenes_produccion')
        .delete()
        .eq('id', id);
  }
}
