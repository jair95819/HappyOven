import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/articulo.dart';
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
  final double consumoDiario; // tasa de consumo diario promedio (RF-018)

  InsumoProyeccionData({
    required this.nombre,
    required this.diasRestantes,
    required this.stockPorcentaje,
    this.consumoDiario = 0,
  });
}

/// Consumo total (salidas + mermas) agregado por día, para el gráfico semanal.
class ConsumoDiaData {
  final DateTime fecha;
  final double cantidad;

  ConsumoDiaData({required this.fecha, required this.cantidad});
}

class DashboardState {
  final bool isLoading;
  final double valorTotalInventario;
  final int insumosConStockBajo;
  final List<Articulo> listaInsumosConStockBajo;
  final List<InsumoProyeccionData> proyecciones;
  final List<ConsumoDiaData> consumoSemanal;
  final String? error;

  DashboardState({
    this.isLoading = true,
    this.valorTotalInventario = 0.0,
    this.insumosConStockBajo = 0,
    this.listaInsumosConStockBajo = const [],
    this.proyecciones = const [],
    this.consumoSemanal = const [],
    this.error,
  });

  /// Total consumido en los últimos 7 días (para encabezados/estados vacíos).
  double get totalConsumoSemanal =>
      consumoSemanal.fold(0.0, (s, d) => s + d.cantidad);

  DashboardState copyWith({
    bool? isLoading,
    double? valorTotalInventario,
    int? insumosConStockBajo,
    List<Articulo>? listaInsumosConStockBajo,
    List<InsumoProyeccionData>? proyecciones,
    List<ConsumoDiaData>? consumoSemanal,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      valorTotalInventario: valorTotalInventario ?? this.valorTotalInventario,
      insumosConStockBajo: insumosConStockBajo ?? this.insumosConStockBajo,
      listaInsumosConStockBajo: listaInsumosConStockBajo ?? this.listaInsumosConStockBajo,
      proyecciones: proyecciones ?? this.proyecciones,
      consumoSemanal: consumoSemanal ?? this.consumoSemanal,
      error: error,
    );
  }
}

/// Calcula el consumo total (salida_produccion + merma) por día para los
/// últimos 7 días terminando en [hoy]. Función pura, expuesta para pruebas.
List<ConsumoDiaData> calcularConsumoSemanal(
  List<dynamic> movimientos, {
  required DateTime hoy,
}) {
  final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
  final dias =
      List.generate(7, (i) => inicioDia.subtract(Duration(days: 6 - i)));
  final mapa = {for (final d in dias) d: 0.0};

  for (final m in movimientos) {
    if (m.tipoMovimiento == TipoMovimiento.salidaProduccion || m.tipoMovimiento == TipoMovimiento.merma) {
      final d = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      if (mapa.containsKey(d)) {
        mapa[d] = mapa[d]! + (m.cantidad as num).toDouble();
      }
    }
  }
  return dias.map((d) => ConsumoDiaData(fecha: d, cantidad: mapa[d]!)).toList();
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
    state = state.copyWith(isLoading: true);

    try {
      final insumos = await _articulosRepository.getInsumos();
      final movimientos = await _movimientosRepository
          .getHistorialMovimientos();

      double valorTotal = 0.0;
      int stockBajo = 0;
      List<Articulo> itemsStockBajo = [];
      List<InsumoProyeccionData> proyecciones = [];

      for (var insumo in insumos) {
        // 1. Calcular KPIs Básicos
        valorTotal += (insumo.stockActual * insumo.precioUnitario);
        if (insumo.stockActual <= insumo.stockMinimo) {
          stockBajo++;
          itemsStockBajo.add(insumo);
        }

        // 2. Calcular Proyección IA (Días restantes)
        // Filtramos salidas de este insumo en los últimos 30 días
        final hace30Dias = DateTime.now().subtract(const Duration(days: 30));

        final salidasRecientes = movimientos
            .where(
              (m) =>
                  m.articuloId == insumo.id &&
                  (m.tipoMovimiento == TipoMovimiento.salidaProduccion ||
                      m.tipoMovimiento == TipoMovimiento.merma) &&
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
              consumoDiario: consumoDiario,
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

      final consumoSemanal =
          calcularConsumoSemanal(movimientos, hoy: DateTime.now());

      state = state.copyWith(
        isLoading: false,
        valorTotalInventario: valorTotal,
        insumosConStockBajo: stockBajo,
        listaInsumosConStockBajo: itemsStockBajo,
        proyecciones: proyecciones,
        consumoSemanal: consumoSemanal,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
