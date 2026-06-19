import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/providers.dart';

/// Resultado del análisis predictivo de un insumo para sugerencias de compra.
class SugerenciaCompra {
  final String insumoId;
  final String nombre;
  final String unidad;
  final double stockActual;
  final double consumoDiario; // tasa de consumo diario promedio (RF-018)
  final int diasRestantes; // proyección hasta agotar el stock (RF-019)
  final double cantidadSugerida; // unidades a reabastecer (RF-020)
  final bool dataInsuficiente; // sin historial confiable (RF-021)
  final int muestras; // nº de movimientos de consumo considerados

  SugerenciaCompra({
    required this.insumoId,
    required this.nombre,
    required this.unidad,
    required this.stockActual,
    required this.consumoDiario,
    required this.diasRestantes,
    required this.cantidadSugerida,
    required this.dataInsuficiente,
    required this.muestras,
  });

  /// Se considera urgente (corto plazo) si se proyecta agotar pronto.
  bool urgente(int umbralDias) => !dataInsuficiente && diasRestantes <= umbralDias;
}

/// Calcula el análisis de sugerencias de compra para cada insumo.
///
/// - [diasVentana]: ventana de historial para estimar el consumo diario.
/// - [minMuestras]: mínimo de movimientos de consumo para una proyección
///   confiable; por debajo se marca `dataInsuficiente` y se omite la predicción (RF-021).
/// - [diasCobertura]: días de stock objetivo para calcular la cantidad a reabastecer (RF-020).
///
/// Función pura, expuesta para pruebas.
List<SugerenciaCompra> calcularSugerenciasCompra(
  List<Articulo> insumos,
  List<Movimiento> movimientos, {
  required DateTime hoy,
  int diasVentana = 90,
  int minMuestras = 3,
  int diasCobertura = 30,
}) {
  final desde = hoy.subtract(Duration(days: diasVentana));

  final resultado = <SugerenciaCompra>[];
  for (final insumo in insumos) {
    final consumos = movimientos.where((m) =>
        m.articuloId == insumo.id &&
        (m.tipoMovimiento == TipoMovimiento.salidaProduccion ||
            m.tipoMovimiento == TipoMovimiento.merma) &&
        m.fecha.isAfter(desde));

    final muestras = consumos.length;
    final totalConsumido = consumos.fold<double>(0, (s, m) => s + m.cantidad);

    // RF-021: sin suficiente data histórica confiable -> omitir la predicción.
    if (muestras < minMuestras || totalConsumido <= 0) {
      resultado.add(SugerenciaCompra(
        insumoId: insumo.id,
        nombre: insumo.nombre,
        unidad: insumo.unidad.dbValue,
        stockActual: insumo.stockActual,
        consumoDiario: 0,
        diasRestantes: -1,
        cantidadSugerida: 0,
        dataInsuficiente: true,
        muestras: muestras,
      ));
      continue;
    }

    final consumoDiario = totalConsumido / diasVentana;
    final diasRestantes = (insumo.stockActual / consumoDiario).floor();

    // Nivel objetivo = consumo proyectado para los días de cobertura deseados.
    final nivelObjetivo = consumoDiario * diasCobertura;
    final cantidadSugerida =
        math.max(0, (nivelObjetivo - insumo.stockActual)).ceilToDouble();

    resultado.add(SugerenciaCompra(
      insumoId: insumo.id,
      nombre: insumo.nombre,
      unidad: insumo.unidad.dbValue,
      stockActual: insumo.stockActual,
      consumoDiario: consumoDiario,
      diasRestantes: diasRestantes,
      cantidadSugerida: cantidadSugerida,
      dataInsuficiente: false,
      muestras: muestras,
    ));
  }

  // Orden: primero con proyección (más urgentes arriba), luego sin datos.
  resultado.sort((a, b) {
    if (a.dataInsuficiente != b.dataInsuficiente) {
      return a.dataInsuficiente ? 1 : -1;
    }
    return a.diasRestantes.compareTo(b.diasRestantes);
  });
  return resultado;
}

final sugerenciasCompraProvider =
    FutureProvider<List<SugerenciaCompra>>((ref) async {
  final articulosRepo = ref.watch(articulosRepositoryProvider);
  final movimientosRepo = ref.watch(movimientosRepositoryProvider);
  final insumos = await articulosRepo.getInsumos();
  final movimientos = await movimientosRepo.getHistorialMovimientos();
  return calcularSugerenciasCompra(insumos, movimientos, hoy: DateTime.now());
});
