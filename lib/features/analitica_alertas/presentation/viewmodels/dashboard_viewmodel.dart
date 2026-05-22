import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/repositories/articulos_repository.dart';
import 'package:happy_oven/core/repositories/movimientos_repository.dart';
import 'package:happy_oven/core/providers.dart';

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
      return DashboardViewModel(
        articulosRepository: ref.watch(articulosRepositoryProvider),
        movimientosRepository: ref.watch(movimientosRepositoryProvider),
      );
    });

// --- ESTADO ---
class InsumoProyeccionData {
  final String nombre;
  final int diasRestantes;
  final double stockPorcentaje;

  InsumoProyeccionData({
    required this.nombre,
    required this.diasRestantes,
    required this.stockPorcentaje,
  });
}

class DashboardState {
  final bool isLoading;
  final double valorTotalInventario;
  final int insumosConStockBajo;
  final List<InsumoProyeccionData> proyecciones;
  final String? error;

  DashboardState({
    this.isLoading = true,
    this.valorTotalInventario = 0.0,
    this.insumosConStockBajo = 0,
    this.proyecciones = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    double? valorTotalInventario,
    int? insumosConStockBajo,
    List<InsumoProyeccionData>? proyecciones,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      valorTotalInventario: valorTotalInventario ?? this.valorTotalInventario,
      insumosConStockBajo: insumosConStockBajo ?? this.insumosConStockBajo,
      proyecciones: proyecciones ?? this.proyecciones,
      error: error,
    );
  }
}

// --- VIEWMODEL ---
class DashboardViewModel extends StateNotifier<DashboardState> {
  final ArticulosRepository _articulosRepository;
  final MovimientosRepository _movimientosRepository;

  DashboardViewModel({
    required ArticulosRepository articulosRepository,
    required MovimientosRepository movimientosRepository,
  }) : _articulosRepository = articulosRepository,
       _movimientosRepository = movimientosRepository,
       super(DashboardState()) {
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final insumos = await _articulosRepository.getInsumos();
      final movimientos = await _movimientosRepository
          .getHistorialMovimientos();

      double valorTotal = 0.0;
      int stockBajo = 0;
      List<InsumoProyeccionData> proyecciones = [];

      for (var insumo in insumos) {
        // 1. Calcular KPIs Básicos
        valorTotal += (insumo.stockActual * insumo.precioUnitario);
        if (insumo.stockActual <= insumo.stockMinimo) {
          stockBajo++;
        }

        // 2. Calcular Proyección IA (Días restantes)
        // Filtramos salidas de este insumo en los últimos 30 días
        final hace30Dias = DateTime.now().subtract(const Duration(days: 30));

        final salidasRecientes = movimientos
            .where(
              (m) =>
                  m.articuloId == insumo.id &&
                  (m.tipoMovimiento == 'salida_produccion' ||
                      m.tipoMovimiento == 'merma') &&
                  m.fecha.isAfter(hace30Dias),
            )
            .toList();

        double cantidadConsumida = 0;
        for (var m in salidasRecientes) {
          cantidadConsumida += m.cantidad;
        }

        double consumoDiario = cantidadConsumida / 30.0;

        int diasRestantes = 999; // Infinito por defecto si no hay consumo
        if (consumoDiario > 0) {
          diasRestantes = (insumo.stockActual / consumoDiario).floor();
        }

        // Para el porcentaje visual de la barra (ej: 14 días o más es 100% verde)
        double porcentaje = (diasRestantes / 14.0).clamp(0.0, 1.0);

        // Solo mostrar los que se agotarán en menos de 30 días, y priorizar los más urgentes
        if (diasRestantes < 30) {
          proyecciones.add(
            InsumoProyeccionData(
              nombre: insumo.nombre,
              diasRestantes: diasRestantes,
              stockPorcentaje: porcentaje,
            ),
          );
        }
      }

      // Ordenar proyecciones: los que se agotan primero arriba
      proyecciones.sort((a, b) => a.diasRestantes.compareTo(b.diasRestantes));

      // Tomar solo el top 5 para no llenar la pantalla
      if (proyecciones.length > 5) {
        proyecciones = proyecciones.sublist(0, 5);
      }

      state = state.copyWith(
        isLoading: false,
        valorTotalInventario: valorTotal,
        insumosConStockBajo: stockBajo,
        proyecciones: proyecciones,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
