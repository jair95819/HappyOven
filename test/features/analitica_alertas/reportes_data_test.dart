import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/reportes_view.dart';

Movimiento _mov({
  required String articuloId,
  required TipoMovimiento tipo,
  required double cantidad,
  required DateTime fecha,
  double? precio,
}) {
  return Movimiento(
    id: 'm-$articuloId-${fecha.day}-$cantidad',
    articuloId: articuloId,
    usuarioId: 'u1',
    tipoMovimiento: tipo,
    cantidad: cantidad,
    precioUnitario: precio,
    porOcr: false,
    fecha: fecha,
  );
}

void main() {
  group('CP-06 / RF-016 - Validación de rango de fechas', () {
    test('CA037 - rango invertido devuelve el mensaje exacto', () {
      final r = validarRangoFechas(DateTime(2026, 6, 10), DateTime(2026, 6, 1));
      expect(r, 'Rango de fechas inválido.');
    });

    test('CA038 - rango válido (o igual) no produce error', () {
      expect(validarRangoFechas(DateTime(2026, 6, 1), DateTime(2026, 6, 10)), isNull);
      expect(validarRangoFechas(DateTime(2026, 6, 1), DateTime(2026, 6, 1)), isNull);
    });
  });

  group('CP-06 / RF-014 - Cálculo de datos del reporte', () {
    final rango = DateTimeRange(
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 3),
    );
    final nombres = {'harina': 'Harina', 'azucar': 'Azúcar'};

    final movimientos = [
      _mov(articuloId: 'harina', tipo: TipoMovimiento.salidaProduccion, cantidad: 10, fecha: DateTime(2026, 6, 1), precio: 2),
      _mov(articuloId: 'harina', tipo: TipoMovimiento.salidaProduccion, cantidad: 5, fecha: DateTime(2026, 6, 2), precio: 2),
      _mov(articuloId: 'azucar', tipo: TipoMovimiento.salidaProduccion, cantidad: 4, fecha: DateTime(2026, 6, 2), precio: 3),
      _mov(articuloId: 'harina', tipo: TipoMovimiento.entrada, cantidad: 20, fecha: DateTime(2026, 6, 1), precio: 2),
      _mov(articuloId: 'azucar', tipo: TipoMovimiento.merma, cantidad: 1, fecha: DateTime(2026, 6, 3), precio: 3),
    ];

    test('CA039 - totales de entradas, salidas, mermas y valor movido', () {
      final data = ReportesData.calcular(movimientos, nombres, rango);
      expect(data.totalEntradas, 20);
      expect(data.totalSalidas, 19); // 10 + 5 + 4
      expect(data.totalMermas, 1);
      // valor = (10*2)+(5*2)+(4*3)+(20*2)+(1*3) = 20+10+12+40+3 = 85
      expect(data.valorMovido, 85);
    });

    test('CA040 - los insumos usan NOMBRE real y se ordenan por consumo', () {
      final data = ReportesData.calcular(movimientos, nombres, rango);
      expect(data.insumos.first.nombre, 'Harina'); // 15 kg, el mayor
      expect(data.insumos.first.cantidad, 15);
      expect(data.insumos[1].nombre, 'Azúcar'); // 4 kg
      // Ningún nombre debe ser el articulo_id crudo.
      expect(data.insumos.every((i) => i.nombre != i.id), isTrue);
    });

    test('CA041 - la serie diaria cubre todo el rango (días continuos)', () {
      final data = ReportesData.calcular(movimientos, nombres, rango);
      expect(data.serieDiaria.length, 3); // 1, 2 y 3 de junio
      expect(data.serieDiaria[0].cantidad, 10); // 6/1
      expect(data.serieDiaria[1].cantidad, 9); // 6/2 -> 5 + 4
      expect(data.serieDiaria[2].cantidad, 0); // 6/3 solo hubo merma (no es consumo)
    });
  });

  group('CP-06 / RF-015 - Exportación CSV', () {
    test('CA042 - el CSV incluye encabezados, nombres de insumo y valores', () {
      final rango = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 2),
      );
      final data = ReportesData.calcular(
        [
          _mov(articuloId: 'harina', tipo: TipoMovimiento.salidaProduccion, cantidad: 10, fecha: DateTime(2026, 6, 1), precio: 2),
        ],
        {'harina': 'Harina'},
        rango,
      );
      final csv = generarCsvReporte(data, rango);

      expect(csv, contains('Reporte Happy Oven'));
      expect(csv, contains('Indicador,Valor'));
      expect(csv, contains('Total salidas (kg),10.00'));
      expect(csv, contains('Insumo,Consumo (kg)'));
      expect(csv, contains('"Harina",10.00'));
      expect(csv, contains('Fecha,Consumo (kg)'));
      expect(csv, contains('2026-06-01,10.00'));
    });
  });
}
