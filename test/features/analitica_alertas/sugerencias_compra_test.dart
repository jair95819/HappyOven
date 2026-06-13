import 'package:flutter_test/flutter_test.dart';

import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/sugerencias_viewmodel.dart';

Articulo _insumo({required String id, required double stock}) => Articulo(
      id: id,
      nombre: id == 'A' ? 'Insumo A' : 'Insumo B',
      tipo: 'insumo',
      unidad: 'kg',
      stockActual: stock,
      stockMinimo: 0,
      precioUnitario: 1,
      activo: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Movimiento _consumo({
  required String insumoId,
  required double cantidad,
  required DateTime fecha,
}) =>
    Movimiento(
      id: 'm-$insumoId-${fecha.day}',
      articuloId: insumoId,
      usuarioId: 'u1',
      tipoMovimiento: 'salida_produccion',
      cantidad: cantidad,
      porOcr: false,
      fecha: fecha,
    );

void main() {
  final hoy = DateTime(2026, 6, 13);

  group('CP-07 / RF-018–021 - Sugerencias de compra', () {
    test(
        'CA046 - Insumo A (con historial): proyecta días, calcula tasa y cantidad a reabastecer',
        () {
      // Insumo A: 12 movimientos de consumo de ~2.7kg en los últimos 90 días.
      final movs = List.generate(
        12,
        (i) => _consumo(
          insumoId: 'A',
          cantidad: 2.7,
          fecha: hoy.subtract(Duration(days: i * 7)),
        ),
      );

      final r = calcularSugerenciasCompra(
        [_insumo(id: 'A', stock: 5)],
        movs,
        hoy: hoy,
        diasVentana: 90,
        diasCobertura: 30,
      );

      final a = r.single;
      expect(a.dataInsuficiente, isFalse);
      expect(a.consumoDiario, closeTo(2.7 * 12 / 90, 0.0001)); // 0.36 kg/día
      // diasRestantes = floor(5 / 0.36) = 13
      expect(a.diasRestantes, 13);
      // cantidadSugerida = ceil(0.36*30 - 5) = ceil(10.8 - 5) = ceil(5.8) = 6
      expect(a.cantidadSugerida, 6);
    });

    test(
        'CA047 - Insumo B (sin historial): se marca data insuficiente y se omite la predicción (RF-021)',
        () {
      final r = calcularSugerenciasCompra(
        [_insumo(id: 'B', stock: 3)],
        const [], // sin movimientos
        hoy: hoy,
      );

      final b = r.single;
      expect(b.dataInsuficiente, isTrue);
      expect(b.cantidadSugerida, 0);
      expect(b.muestras, 0);
    });

    test(
        'CA048 - con pocas muestras (< mínimo) también se considera data insuficiente',
        () {
      final movs = [
        _consumo(insumoId: 'B', cantidad: 1, fecha: hoy.subtract(const Duration(days: 2))),
      ];
      final r = calcularSugerenciasCompra(
        [_insumo(id: 'B', stock: 3)],
        movs,
        hoy: hoy,
        minMuestras: 3,
      );
      expect(r.single.dataInsuficiente, isTrue);
    });

    test('CA049 - ordena: con proyección (más urgente primero) y luego sin datos', () {
      final movsA = List.generate(
        6,
        (i) => _consumo(insumoId: 'A', cantidad: 5, fecha: hoy.subtract(Duration(days: i * 5))),
      );
      final r = calcularSugerenciasCompra(
        [_insumo(id: 'B', stock: 3), _insumo(id: 'A', stock: 2)],
        movsA,
        hoy: hoy,
      );
      expect(r.first.nombre, 'Insumo A'); // tiene proyección -> arriba
      expect(r.last.dataInsuficiente, isTrue); // B sin datos -> abajo
    });
  });
}
