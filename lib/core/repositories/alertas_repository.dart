import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/models/alerta.dart';

class AlertasRepository {
  final SupabaseService _supabaseService;

  AlertasRepository({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  // Obtener alertas no leídas
  Future<List<Alerta>> getAlertasPendientes() async {
    final response = await _supabaseService.client
        .from('alertas')
        .select()
        .eq('leida', false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Alerta.fromJson(json)).toList();
  }

  // Obtener todas las alertas
  Future<List<Alerta>> getHistorialAlertas() async {
    final response = await _supabaseService.client
        .from('alertas')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Alerta.fromJson(json)).toList();
  }

  // Crear una alerta
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

  // Marcar alerta como leída
  Future<void> marcarComoLeida(String id) async {
    await _supabaseService.client
        .from('alertas')
        .update({'leida': true})
        .eq('id', id);
  }
}
