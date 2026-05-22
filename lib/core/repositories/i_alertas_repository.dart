import 'package:happy_oven/core/models/alerta.dart';

/// Interfaz que define el contrato para el acceso a datos de Alertas.
/// Las alertas informan sobre stock bajo, anomalías de IA, etc.
abstract class IAlertasRepository {
  /// Obtiene la lista de alertas que aún no han sido leídas por el usuario.
  Future<List<Alerta>> getAlertasPendientes();

  /// Obtiene el historial completo de alertas (leídas y no leídas), ordenadas por fecha.
  Future<List<Alerta>> getHistorialAlertas();

  /// Guarda una nueva alerta en la base de datos y la devuelve con su ID generado.
  Future<Alerta> createAlerta(Alerta alerta);

  /// Marca una alerta específica como leída usando su [id].
  Future<void> marcarComoLeida(String id);

  /// Marca masivamente todas las alertas pendientes como leídas.
  Future<void> marcarTodasComoLeidas();

  /// Elimina definitivamente una alerta de la base de datos mediante su [id].
  Future<void> deleteAlerta(String id);
}