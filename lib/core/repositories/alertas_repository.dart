import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/alerta.dart';
import 'package:happy_oven/core/repositories/i_alertas_repository.dart';

/// Implementación de la interfaz [IAlertasRepository] utilizando Supabase como backend.
class AlertasRepository implements IAlertasRepository {
  final SupabaseService _supabaseService;

  AlertasRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  /// Consulta a Supabase las alertas donde la columna `leida` sea falsa.
  @override
  Future<List<Alerta>> getAlertasPendientes() async {
    final response = await _supabaseService.client
        .from('alertas')
        .select()
        .eq('leida', false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Alerta.fromJson(json)).toList();
  }

  /// Consulta a Supabase todas las alertas sin aplicar filtros, ordenadas por la más reciente.
  @override
  Future<List<Alerta>> getHistorialAlertas() async {
    final response = await _supabaseService.client
        .from('alertas')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Alerta.fromJson(json)).toList();
  }

  /// Inserta un nuevo registro en la tabla `alertas`. Se omite el ID para que Supabase lo autogenere.
  @override
  Future<Alerta> createAlerta(Alerta alerta) async {
    final data = alerta.toJson();
    data.remove('id');

    final response = await _supabaseService.client
        .from('alertas')
        .insert(data)
        .select()
        .single();

    return Alerta.fromJson(response);
  }

  /// Actualiza en Supabase el estado del campo `leida` a true para la alerta con el [id] provisto.
  @override
  Future<void> marcarComoLeida(String id) async {
    await _supabaseService.client
        .from('alertas')
        .update({'leida': true})
        .eq('id', id);
  }

  /// Actualiza masivamente en Supabase el estado `leida` a true de todas las alertas pendientes.
  @override
  Future<void> marcarTodasComoLeidas() async {
    await _supabaseService.client
        .from('alertas')
        .update({'leida': true})
        .eq('leida', false);
  }

  /// Elimina definitivamente el registro de la tabla `alertas` en Supabase usando su [id].
  @override
  Future<void> deleteAlerta(String id) async {
    await _supabaseService.client
        .from('alertas')
        .delete()
        .eq('id', id);
  }
}
