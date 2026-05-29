import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/repositories/i_movimientos_repository.dart';

/// Implementación de [IMovimientosRepository] utilizando la tabla `movimientos` de Supabase.
class MovimientosRepository implements IMovimientosRepository {
  final SupabaseService _supabaseService;

  MovimientosRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  /// Consulta a Supabase todos los movimientos, ordenados de forma descendente por fecha (más recientes primero).
  @override
  Future<List<Movimiento>> getHistorialMovimientos() async {
    final response = await _supabaseService.client
        .from('movimientos')
        .select()
        .order('fecha', ascending: false);

    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }

  /// Filtra en Supabase los movimientos donde la columna `articulo_id` coincide con el [articuloId].
  @override
  Future<List<Movimiento>> getMovimientosPorArticulo(String articuloId) async {
    final response = await _supabaseService.client
        .from('movimientos')
        .select()
        .eq('articulo_id', articuloId)
        .order('fecha', ascending: false);

    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }

  /// Inserta un nuevo movimiento en la tabla de Supabase (las triggers de base de datos o lógica superior deben ajustar el stock).
  @override
  Future<Movimiento> registrarMovimiento(Movimiento movimiento) async {
    final data = movimiento.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('movimientos')
        .insert(data)
        .select()
        .single();

    return Movimiento.fromJson(response);
  }

  /// Elimina de forma forzada un movimiento específico de la base de datos por su ID.
  @override
  Future<void> deleteMovimiento(String id) async {
    await _supabaseService.client
        .from('movimientos')
        .delete()
        .eq('id', id);
  }

  @override
  Future<List<Movimiento>> getMovimientosPorRango(DateTime inicio, DateTime fin) async {
    final response = await _supabaseService.client
        .from('movimientos')
        .select()
        .gte('fecha', inicio.toIso8601String())
        .lte('fecha', fin.toIso8601String())
        .order('fecha', ascending: true);

    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }
}
