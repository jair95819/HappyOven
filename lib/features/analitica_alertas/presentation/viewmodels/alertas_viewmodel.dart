import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/alerta.dart';
import 'package:happy_oven/core/repositories/alertas_repository.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

// ── Provider del repositorio
final alertasRepositoryProvider = Provider<AlertasRepository>((ref) {
  return AlertasRepository(supabaseService: ref.watch(supabaseServiceProvider));
});

// ── Provider del ViewModel
final alertasViewModelProvider =
    StateNotifierProvider<AlertasViewModel, AsyncValue<List<Alerta>>>((ref) {
  return AlertasViewModel(ref.watch(alertasRepositoryProvider));
});

class AlertasViewModel extends StateNotifier<AsyncValue<List<Alerta>>> {
  final AlertasRepository _repository;

  AlertasViewModel(this._repository) : super(const AsyncLoading()) {
    cargarAlertas();
  }

  Future<void> cargarAlertas() async {
    try {
      state = const AsyncLoading();
      final alertas = await _repository.getHistorialAlertas();
      state = AsyncData(alertas);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  int get noLeidas {
    final alertas = state.value ?? [];
    return alertas.where((a) => !a.leida).length;
  }

  Future<bool> marcarComoLeida(String id) async {
    try {
      await _repository.marcarComoLeida(id);
      await cargarAlertas();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> marcarTodasComoLeidas() async {
    try {
      await _repository.marcarTodasComoLeidas();
      await cargarAlertas();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarAlerta(String id) async {
    try {
      await _repository.deleteAlerta(id);
      await cargarAlertas();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crea una alerta de stock bajo para un artículo específico
  Future<bool> crearAlertaStockBajo(String articuloId, String nombreArticulo, double stockActual) async {
    try {
      final alerta = Alerta(
        id: '',
        articuloId: articuloId,
        tipo: 'stock_bajo',
        titulo: 'Stock bajo',
        mensaje: 'Stock de $nombreArticulo por debajo del mínimo ($stockActual unidades restantes).',
        leida: false,
        createdAt: DateTime.now(),
      );
      await _repository.createAlerta(alerta);
      await cargarAlertas();
      return true;
    } catch (e) {
      return false;
    }
  }
}
