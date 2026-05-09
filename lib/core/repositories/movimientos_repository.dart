import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/movimiento.dart';

class MovimientosRepository {
  final SupabaseService _supabaseService;

  MovimientosRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Obtener historial de todos los movimientos ordenados por fecha
  Future<List<Movimiento>> getHistorialMovimientos() async {
    final response = await _supabaseService.client
        .from('movimientos')
        .select()
        .order('fecha', ascending: false);

    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }

  // Obtener movimientos de un artículo específico
  Future<List<Movimiento>> getMovimientosPorArticulo(String articuloId) async {
    final response = await _supabaseService.client
        .from('movimientos')
        .select()
        .eq('articulo_id', articuloId)
        .order('fecha', ascending: false);

    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }

  // Registrar un nuevo movimiento
  Future<Movimiento> registrarMovimiento(Movimiento movimiento) async {
    final data = movimiento.toJson();
    data.remove('id');
    
    // Si la fecha enviada es exactamente DateTime.now, podemos dejar que DB ponga el default
    // pero es mejor enviar lo que dictó el modelo.

    final response = await _supabaseService.client
        .from('movimientos')
        .insert(data)
        .select()
        .single();

    return Movimiento.fromJson(response);
  }

  // Elminar movimiento (No recomendado en contabilidad/kardex a menos que sea un error crítico)
  Future<void> deleteMovimiento(String id) async {
    await _supabaseService.client
        .from('movimientos')
        .delete()
        .eq('id', id);
  }
}
