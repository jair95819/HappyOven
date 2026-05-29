import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/services/local_storage_service.dart';
import 'package:happy_oven/core/services/notification_service.dart';
import 'package:happy_oven/core/services/stock_monitor_service.dart';
import 'package:happy_oven/core/repositories/articulos_repository.dart';
import 'package:happy_oven/core/repositories/categorias_repository.dart';
import 'package:happy_oven/core/repositories/movimientos_repository.dart';
import 'package:happy_oven/core/repositories/recetas_repository.dart';
import 'package:happy_oven/core/repositories/alertas_repository.dart';
import 'package:happy_oven/core/repositories/ordenes_produccion_repository.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final articulosRepositoryProvider = Provider<ArticulosRepository>((ref) {
  return ArticulosRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final categoriasRepositoryProvider = Provider<CategoriasRepository>((ref) {
  return CategoriasRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final movimientosRepositoryProvider = Provider<MovimientosRepository>((ref) {
  return MovimientosRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final recetasRepositoryProvider = Provider<RecetasRepository>((ref) {
  return RecetasRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final alertasRepositoryProvider = Provider<AlertasRepository>((ref) {
  return AlertasRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final ordenesProduccionRepositoryProvider = Provider<OrdenesProduccionRepository>((ref) {
  return OrdenesProduccionRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final stockMonitorServiceProvider = Provider<StockMonitorService>((ref) {
  return StockMonitorService(
    articulosRepo: ref.watch(articulosRepositoryProvider),
    alertasRepo: ref.watch(alertasRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});