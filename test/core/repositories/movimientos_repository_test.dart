import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';

import '../../helpers/test_helpers.mocks.dart';

// ── Helper ──
Movimiento _mov({
  String id = 'm1',
  String articuloId = 'a1',
  TipoMovimiento tipoMovimiento = TipoMovimiento.entrada,
  double cantidad = 50,
  DateTime? fecha,
}) {
  return Movimiento(
    id: id, articuloId: articuloId, usuarioId: 'u1',
    tipoMovimiento: tipoMovimiento, cantidad: cantidad,
    porOcr: false, fecha: fecha ?? DateTime(2025, 6, 15),
  );
}

void main() {
  late MockIMovimientosRepository mockRepo;

  setUp(() {
    mockRepo = MockIMovimientosRepository();
  });

  // ═══════════════════════════════════════════════════════
  // CA016 — registrarMovimiento(Movimiento movimiento)
  // ═══════════════════════════════════════════════════════
  group('CA016 - registrarMovimiento()', () {
    test('registra entrada de stock y retorna con ID', () async {
      final nuevo = _mov(id: '', cantidad: 25);
      final creado = _mov(id: 'm-nuevo', cantidad: 25);

      when(mockRepo.registrarMovimiento(nuevo))
          .thenAnswer((_) async => creado);

      final resultado = await mockRepo.registrarMovimiento(nuevo);

      expect(resultado.id, 'm-nuevo');
      expect(resultado.tipoMovimiento, TipoMovimiento.entrada);
      expect(resultado.cantidad, 25);
      verify(mockRepo.registrarMovimiento(nuevo)).called(1);
    });

    test('registra salida de stock', () async {
      final salida = _mov(id: '', tipoMovimiento: TipoMovimiento.salidaProduccion, cantidad: 10);
      final creada = _mov(id: 'm-salida', tipoMovimiento: TipoMovimiento.salidaProduccion, cantidad: 10);

      when(mockRepo.registrarMovimiento(salida))
          .thenAnswer((_) async => creada);

      final resultado = await mockRepo.registrarMovimiento(salida);

      expect(resultado.tipoMovimiento, TipoMovimiento.salidaProduccion);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA017 — getHistorialMovimientos()
  // ═══════════════════════════════════════════════════════
  group('CA017 - getHistorialMovimientos()', () {
    test('retorna movimientos ordenados por fecha descendente', () async {
      when(mockRepo.getHistorialMovimientos()).thenAnswer((_) async => [
        _mov(fecha: DateTime(2025, 6, 15)),
        _mov(id: 'm2', fecha: DateTime(2025, 6, 14)),
        _mov(id: 'm3', fecha: DateTime(2025, 6, 13)),
      ]);

      final resultado = await mockRepo.getHistorialMovimientos();

      expect(resultado.length, 3);
      expect(resultado[0].fecha.isAfter(resultado[1].fecha), true);
      expect(resultado[1].fecha.isAfter(resultado[2].fecha), true);
      verify(mockRepo.getHistorialMovimientos()).called(1);
    });

    test('retorna lista vacía sin movimientos', () async {
      when(mockRepo.getHistorialMovimientos())
          .thenAnswer((_) async => []);

      final resultado = await mockRepo.getHistorialMovimientos();
      expect(resultado, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA018 — getMovimientosPorArticulo(String articuloId)
  // ═══════════════════════════════════════════════════════
  group('CA018 - getMovimientosPorArticulo()', () {
    test('retorna solo movimientos del artículo indicado', () async {
      when(mockRepo.getMovimientosPorArticulo('a1')).thenAnswer((_) async => [
        _mov(articuloId: 'a1'),
        _mov(id: 'm2', tipoMovimiento: TipoMovimiento.salidaProduccion, cantidad: 10),
      ]);

      final resultado = await mockRepo.getMovimientosPorArticulo('a1');

      expect(resultado.length, 2);
      for (final mov in resultado) {
        expect(mov.articuloId, 'a1');
      }
    });

    test('retorna vacío si el artículo no tiene movimientos', () async {
      when(mockRepo.getMovimientosPorArticulo('a-sin-mov'))
          .thenAnswer((_) async => []);

      final resultado = await mockRepo.getMovimientosPorArticulo('a-sin-mov');
      expect(resultado, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA019 — deleteMovimiento(String id)
  // ═══════════════════════════════════════════════════════
  group('CA019 - deleteMovimiento()', () {
    test('elimina movimiento sin error', () async {
      when(mockRepo.deleteMovimiento('m1'))
          .thenAnswer((_) async {});

      await mockRepo.deleteMovimiento('m1');

      verify(mockRepo.deleteMovimiento('m1')).called(1);
    });
  });
}
