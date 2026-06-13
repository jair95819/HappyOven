import 'package:flutter_test/flutter_test.dart';

import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/dashboard_viewmodel.dart';

Movimiento _mov({
  required String tipo,
  required double cantidad,
  required DateTime fecha,
}) {
  return Movimiento(
    id: 'm-${fecha.millisecondsSinceEpoch}-$cantidad',
    articuloId: 'art-1',
    usuarioId: 'u1',
    tipoMovimiento: tipo,
    cantidad: cantidad,
    porOcr: false,
    fecha: fecha,
  );
}

void main() {
  group('CP-06 (Dashboard) - Consumo semanal real', () {
    final hoy = DateTime(2026, 6, 13, 15, 0); // con hora, para validar truncado a día

    test('CA043 - genera exactamente 7 días terminando en hoy', () {
      final serie = calcularConsumoSemanal([], hoy: hoy);
      expect(serie.length, 7);
      expect(serie.first.fecha, DateTime(2026, 6, 7));
      expect(serie.last.fecha, DateTime(2026, 6, 13));
      expect(serie.every((d) => d.cantidad == 0), isTrue);
    });

    test('CA044 - suma salidas y mermas por día; ignora entradas', () {
      final serie = calcularConsumoSemanal([
        _mov(tipo: 'salida_produccion', cantidad: 8, fecha: DateTime(2026, 6, 13, 9)),
        _mov(tipo: 'merma', cantidad: 2, fecha: DateTime(2026, 6, 13, 18)),
        _mov(tipo: 'entrada', cantidad: 100, fecha: DateTime(2026, 6, 13, 10)),
        _mov(tipo: 'salida_produccion', cantidad: 5, fecha: DateTime(2026, 6, 10, 12)),
      ], hoy: hoy);

      expect(serie.last.cantidad, 10); // 8 + 2 (entrada ignorada)
      final dia10 = serie.firstWhere((d) => d.fecha == DateTime(2026, 6, 10));
      expect(dia10.cantidad, 5);
    });

    test('CA045 - ignora movimientos fuera de la ventana de 7 días', () {
      final serie = calcularConsumoSemanal([
        _mov(tipo: 'salida_produccion', cantidad: 99, fecha: DateTime(2026, 6, 1)),
      ], hoy: hoy);
      expect(serie.fold<double>(0, (s, d) => s + d.cantidad), 0);
    });
  });
}
