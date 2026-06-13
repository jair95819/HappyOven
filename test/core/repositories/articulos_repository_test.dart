import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_oven/core/models/articulo.dart';

import '../../helpers/test_helpers.mocks.dart';

// ── Helper ──
Articulo _art({
  String id = 'a1',
  String nombre = 'Harina',
  String tipo = 'insumo',
  String unidad = 'kg',
  double stockActual = 100,
  double stockMinimo = 10,
  double precio = 5.0,
}) {
  return Articulo(
    id: id, nombre: nombre, categoriaId: null,
    tipo: tipo, unidad: unidad, stockActual: stockActual,
    stockMinimo: stockMinimo, precioUnitario: precio, activo: true,
    createdAt: DateTime(2025, 1), updatedAt: DateTime(2025, 1),
  );
}

void main() {
  late MockIArticulosRepository mockRepo;

  setUp(() {
    mockRepo = MockIArticulosRepository();
  });

  // ═══════════════════════════════════════════════════════
  // CA001 — getArticulos()
  // ═══════════════════════════════════════════════════════
  group('CA001 - getArticulos()', () {
    test('retorna lista de artículos ordenada alfabéticamente', () async {
      final articulosFake = [
        _art(nombre: 'Azúcar'),
        _art(id: 'a2'),
        _art(id: 'a3', nombre: 'Mantequilla'),
      ];
      when(mockRepo.getArticulos()).thenAnswer((_) async => articulosFake);

      final resultado = await mockRepo.getArticulos();

      expect(resultado.length, 3);
      expect(resultado[0].nombre, 'Azúcar');
      expect(resultado[1].nombre, 'Harina');
      expect(resultado[2].nombre, 'Mantequilla');
      verify(mockRepo.getArticulos()).called(1);
    });

    test('retorna lista vacía cuando no hay artículos', () async {
      when(mockRepo.getArticulos()).thenAnswer((_) async => []);

      final resultado = await mockRepo.getArticulos();
      expect(resultado, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA002 — getInsumos()
  // ═══════════════════════════════════════════════════════
  group('CA002 - getInsumos()', () {
    test('retorna solo artículos de tipo insumo', () async {
      final insumosFake = [
        _art(nombre: 'Harina'),
        _art(id: 'a2', nombre: 'Azúcar'),
      ];
      when(mockRepo.getInsumos()).thenAnswer((_) async => insumosFake);

      final resultado = await mockRepo.getInsumos();

      expect(resultado.length, 2);
      for (final art in resultado) {
        expect(art.tipo, 'insumo');
      }
      verify(mockRepo.getInsumos()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA003 — getProductosFinales()
  // ═══════════════════════════════════════════════════════
  group('CA003 - getProductosFinales()', () {
    test('retorna solo artículos de tipo producto_final', () async {
      final productosFake = [
        _art(id: 'p1', nombre: 'Pan francés', tipo: 'producto_final'),
        _art(id: 'p2', nombre: 'Torta', tipo: 'producto_final'),
      ];
      when(mockRepo.getProductosFinales()).thenAnswer((_) async => productosFake);

      final resultado = await mockRepo.getProductosFinales();

      expect(resultado.length, 2);
      for (final art in resultado) {
        expect(art.tipo, 'producto_final');
      }
      verify(mockRepo.getProductosFinales()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA004 — getArticuloById(String id)
  // ═══════════════════════════════════════════════════════
  group('CA004 - getArticuloById()', () {
    test('retorna el artículo cuando existe', () async {
      when(mockRepo.getArticuloById('a1'))
          .thenAnswer((_) async => _art(nombre: 'Harina'));

      final resultado = await mockRepo.getArticuloById('a1');

      expect(resultado, isNotNull);
      expect(resultado!.id, 'a1');
      expect(resultado.nombre, 'Harina');
    });

    test('retorna null cuando no existe', () async {
      when(mockRepo.getArticuloById('no-existe'))
          .thenAnswer((_) async => null);

      final resultado = await mockRepo.getArticuloById('no-existe');
      expect(resultado, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA005 — createArticulo(Articulo articulo)
  // ═══════════════════════════════════════════════════════
  group('CA005 - createArticulo()', () {
    test('crea artículo y retorna con ID asignado por BD', () async {
      final articuloSinId = _art(id: '', nombre: 'Leche');
      final articuloConId = _art(id: 'nuevo-id-abc', nombre: 'Leche');

      when(mockRepo.createArticulo(articuloSinId))
          .thenAnswer((_) async => articuloConId);

      final resultado = await mockRepo.createArticulo(articuloSinId);

      expect(resultado.id, isNotEmpty);
      expect(resultado.id, 'nuevo-id-abc');
      expect(resultado.nombre, 'Leche');
      verify(mockRepo.createArticulo(articuloSinId)).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA006 — updateArticulo(Articulo articulo)
  // ═══════════════════════════════════════════════════════
  group('CA006 - updateArticulo()', () {
    test('actualiza artículo y retorna con datos actualizados', () async {
      final articuloActualizado = Articulo(
        id: 'a1', nombre: 'Harina Integral', categoriaId: null,
        tipo: 'insumo', unidad: 'kg', stockActual: 80,
        stockMinimo: 10, precioUnitario: 6.0, activo: true,
        createdAt: DateTime(2025, 1),
        updatedAt: DateTime(2025, 6, 15),
      );

      when(mockRepo.updateArticulo(any))
          .thenAnswer((_) async => articuloActualizado);

      final resultado = await mockRepo.updateArticulo(articuloActualizado);

      expect(resultado.nombre, 'Harina Integral');
      expect(resultado.precioUnitario, 6.0);
      verify(mockRepo.updateArticulo(any)).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA007 — deleteArticulo(String id)
  // ═══════════════════════════════════════════════════════
  group('CA007 - deleteArticulo()', () {
    test('elimina artículo sin lanzar excepción', () async {
      when(mockRepo.deleteArticulo('a1'))
          .thenAnswer((_) async {});

      await mockRepo.deleteArticulo('a1');

      verify(mockRepo.deleteArticulo('a1')).called(1);
    });

    test('lanza excepción si falla', () async {
      when(mockRepo.deleteArticulo('no-existe'))
          .thenThrow(Exception('Artículo no encontrado'));

      expect(
        () => mockRepo.deleteArticulo('no-existe'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
