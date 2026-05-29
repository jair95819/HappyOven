import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:happy_oven/core/models/alerta.dart';
import 'package:happy_oven/core/repositories/i_articulos_repository.dart';
import 'package:happy_oven/core/repositories/i_alertas_repository.dart';
import 'package:happy_oven/core/services/notification_service.dart';

/// Servicio que monitorea el stock de artículos periódicamente y genera
/// alertas + notificaciones push cuando hay artículos con stock bajo o crítico.
class StockMonitorService {
  final IArticulosRepository _articulosRepo;
  final IAlertasRepository _alertasRepo;
  final NotificationService _notificationService;

  Timer? _timer;
  bool _isChecking = false;

  /// Intervalo entre chequeos (20 minutos)
  static const Duration checkInterval = Duration(minutes: 20);

  StockMonitorService({
    required IArticulosRepository articulosRepo,
    required IAlertasRepository alertasRepo,
    required NotificationService notificationService,
  })  : _articulosRepo = articulosRepo,
        _alertasRepo = alertasRepo,
        _notificationService = notificationService;

  /// Inicia el monitoreo periódico. Ejecuta un chequeo inmediato y luego
  /// programa un timer cada [checkInterval].
  void startMonitoring() {
    if (_timer != null) return; // Ya está corriendo

    debugPrint('[StockMonitor] Iniciando monitoreo cada ${checkInterval.inMinutes} min');

    // Chequeo inmediato al iniciar
    checkNow();

    // Timer periódico
    _timer = Timer.periodic(checkInterval, (_) => checkNow());
  }

  /// Detiene el monitoreo periódico.
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    debugPrint('[StockMonitor] Monitoreo detenido');
  }

  /// Ejecuta un chequeo inmediato del stock de todos los artículos.
  Future<void> checkNow() async {
    if (_isChecking) return; // Evitar chequeos concurrentes
    _isChecking = true;

    try {
      debugPrint('[StockMonitor] Ejecutando chequeo de stock...');

      final articulos = await _articulosRepo.getArticulos();
      final alertasExistentes = await _alertasRepo.getAlertasPendientes();

      // IDs de artículos que ya tienen una alerta sin leer
      final idsConAlerta = alertasExistentes
          .where((a) => a.tipo == 'stock_bajo' && a.articuloId != null)
          .map((a) => a.articuloId!)
          .toSet();

      int totalBajo = 0;
      int totalCritico = 0;

      for (final art in articulos) {
        if (art.stockMinimo <= 0) continue; // Sin mínimo configurado

        final ratio = art.stockActual / art.stockMinimo;

        if (ratio > 1.0) continue; // Stock normal, no hacer nada

        final esCritico = ratio <= 0.5;
        final severidad = esCritico ? 'critico' : 'bajo';

        if (esCritico) {
          totalCritico++;
        } else {
          totalBajo++;
        }

        // Solo crear alerta en Supabase si no hay una pendiente para este artículo
        if (!idsConAlerta.contains(art.id)) {
          try {
            final titulo = esCritico ? 'Stock crítico' : 'Stock bajo';
            final mensaje = esCritico
                ? '⚠️ ${art.nombre} tiene solo ${art.stockActual.toStringAsFixed(0)} ${art.unidad} '
                  '(mínimo: ${art.stockMinimo.toStringAsFixed(0)}). ¡Acción urgente!'
                : '${art.nombre} está en ${art.stockActual.toStringAsFixed(0)} ${art.unidad} '
                  '(mínimo: ${art.stockMinimo.toStringAsFixed(0)}). Considera reabastecer.';

            await _alertasRepo.createAlerta(Alerta(
              id: '',
              articuloId: art.id,
              tipo: 'stock_bajo',
              titulo: titulo,
              mensaje: mensaje,
              leida: false,
              createdAt: DateTime.now(),
            ));

            debugPrint('[StockMonitor] Alerta creada para: ${art.nombre} ($severidad)');
          } catch (e) {
            debugPrint('[StockMonitor] Error al crear alerta para ${art.nombre}: $e');
          }
        }
      }

      // Enviar notificación push si hay artículos afectados
      if (totalBajo > 0 || totalCritico > 0) {
        await _notificationService.showResumenAlert(
          totalBajo: totalBajo,
          totalCritico: totalCritico,
        );
        debugPrint(
            '[StockMonitor] Push enviado: $totalCritico críticos, $totalBajo bajos');
      } else {
        debugPrint('[StockMonitor] Todo el stock está normal ✅');
      }
    } catch (e) {
      debugPrint('[StockMonitor] Error durante chequeo: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Indica si el monitor está activo.
  bool get isRunning => _timer != null;
}
