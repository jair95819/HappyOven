import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Servicio singleton para gestionar notificaciones locales push.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Canal de notificación para alertas de stock
  static const String _channelId = 'stock_alerts';
  static const String _channelName = 'Alertas de Stock';
  static const String _channelDesc =
      'Notificaciones de stock bajo o crítico de artículos';

  /// Inicializa el plugin de notificaciones locales.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('[NotificationService] Inicializado correctamente');
  }

  /// Solicita permisos de notificación al usuario (Android 13+).
  Future<bool> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[NotificationService] Permiso de notificaciones: $granted');
      return granted ?? false;
    }
    return false;
  }

  /// Muestra una notificación push de stock con severidad.
  ///
  /// [id] debe ser único por notificación. Se puede generar a partir del hashCode
  /// del articuloId para evitar duplicados visuales.
  /// [severidad] puede ser 'critico' o 'bajo'.
  Future<void> showStockAlert({
    required int id,
    required String titulo,
    required String mensaje,
    required String severidad,
  }) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: severidad == 'critico'
          ? const Color(0xFFE53935) // rojo
          : const Color(0xFFFF8C42), // naranja
      styleInformation: BigTextStyleInformation(mensaje),
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, titulo, mensaje, details);
    debugPrint('[NotificationService] Notificación enviada: $titulo');
  }

  /// Muestra una notificación resumen cuando hay múltiples artículos afectados.
  Future<void> showResumenAlert({
    required int totalBajo,
    required int totalCritico,
  }) async {
    if (!_initialized) return;

    final total = totalBajo + totalCritico;
    if (total == 0) return;

    String titulo;
    String mensaje;

    if (totalCritico > 0 && totalBajo > 0) {
      titulo = '⚠️ $total artículos requieren atención';
      mensaje =
          '$totalCritico con stock crítico y $totalBajo con stock bajo. Revisa el inventario.';
    } else if (totalCritico > 0) {
      titulo = '🔴 $totalCritico artículos con stock crítico';
      mensaje =
          'Hay $totalCritico artículos por debajo del 50% del stock mínimo. Acción urgente requerida.';
    } else {
      titulo = '🟠 $totalBajo artículos con stock bajo';
      mensaje =
          'Hay $totalBajo artículos cerca o por debajo del stock mínimo. Considera reabastecer.';
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: totalCritico > 0
          ? const Color(0xFFE53935)
          : const Color(0xFFFF8C42),
      styleInformation: BigTextStyleInformation(mensaje),
    );

    final details = NotificationDetails(android: androidDetails);

    // ID fijo 0 para el resumen (se reemplaza cada vez)
    await _plugin.show(0, titulo, mensaje, details);
  }

  /// Cancela todas las notificaciones visibles.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Handler cuando el usuario toca una notificación.
  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
        '[NotificationService] Notificación tocada: ${response.payload}');
    // Aquí se podría navegar a la vista de alertas si fuera necesario.
  }
}
