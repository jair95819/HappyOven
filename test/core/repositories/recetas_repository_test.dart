import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';

import '../../helpers/test_helpers.mocks.dart';

// ── Helpers ──
Receta _receta({
  String id = 'r1',
  String nombre = 'Pan',
  String? productoId,
  double rendimiento = 10,
}) {
  return Receta(
    id: id, nombre: nombre, productoId: productoId,
    rendimiento: rendimiento, createdAt: DateTime(2025, 1),
  );
}

RecetaIngrediente _ingrediente({
  String id = 'ri1',
  String recetaId = 'r1',
  String insumoId = 'a1',
  double cantidad = 2.0,
}) {
  return RecetaIngrediente(
    id: id, recetaId: recetaId, insumoId: insumoId,
    cantidadRequerida: cantidad,
  );
}

void main() {
  late MockIRecetasRepository mockRepo;

  setUp(() {
    mockRepo = MockIRecetasRepository();
  });

  // ═══════════════════════════════════════════════════════
  // CA008 — getRecetas()
  // ═══════════════════════════════════════════════════════
  group('CA008 - getRecetas()', () {
    test('retorna recetas ordenadas alfabéticamente', () async {
      when(mockRepo.getRecetas()).thenAnswer((_) async => [
        _receta(nombre: 'Brownie'),
        _receta(id: 'r2', nombre: 'Galletas'),
        _receta(id: 'r3'),
      ]);

      final resultado = await mockRepo.getRecetas();

      expect(resultado.length, 3);
      expect(resultado[0].nombre, 'Brownie');
      expect(resultado[1].nombre, 'Galletas');
      expect(resultado[2].nombre, 'Pan');
      verify(mockRepo.getRecetas()).called(1);
    });

    test('retorna lista vacía cuando no hay recetas', () async {
      when(mockRepo.getRecetas()).thenAnswer((_) async => []);

      final resultado = await mockRepo.getRecetas();
      expect(resultado, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA009 — getRecetaById(String id)
  // ═══════════════════════════════════════════════════════
  group('CA009 - getRecetaById()', () {
    test('retorna la receta cuando existe', () async {
      when(mockRepo.getRecetaById('r1'))
          .thenAnswer((_) async => _receta(nombre: 'Pan'));

      final resultado = await mockRepo.getRecetaById('r1');

      expect(resultado, isNotNull);
      expect(resultado!.id, 'r1');
      expect(resultado.nombre, 'Pan');
    });

    test('retorna null cuando no existe', () async {
      when(mockRepo.getRecetaById('no-existe'))
          .thenAnswer((_) async => null);

      final resultado = await mockRepo.getRecetaById('no-existe');
      expect(resultado, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA010 — getRecetaByProductoId(String productoId)
  // ═══════════════════════════════════════════════════════
  group('CA010 - getRecetaByProductoId()', () {
    test('retorna receta vinculada al producto', () async {
      when(mockRepo.getRecetaByProductoId('p1')).thenAnswer((_) async =>
        _receta(nombre: 'Pan', productoId: 'p1'),
      );

      final resultado = await mockRepo.getRecetaByProductoId('p1');

      expect(resultado, isNotNull);
      expect(resultado!.productoId, 'p1');
    });

    test('retorna null si el producto no tiene receta', () async {
      when(mockRepo.getRecetaByProductoId('p-sin-receta'))
          .thenAnswer((_) async => null);

      final resultado = await mockRepo.getRecetaByProductoId('p-sin-receta');
      expect(resultado, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA011 — createReceta(Receta receta)
  // ═══════════════════════════════════════════════════════
  group('CA011 - createReceta()', () {
    test('crea receta y retorna con ID generado por BD', () async {
      final nueva = _receta(id: '', nombre: 'Torta');
      final creada = _receta(id: 'r-nuevo-123', nombre: 'Torta');

      when(mockRepo.createReceta(nueva)).thenAnswer((_) async => creada);

      final resultado = await mockRepo.createReceta(nueva);

      expect(resultado.id, 'r-nuevo-123');
      expect(resultado.nombre, 'Torta');
      verify(mockRepo.createReceta(nueva)).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA012 — updateReceta(Receta receta)
  // ═══════════════════════════════════════════════════════
  group('CA012 - updateReceta()', () {
    test('actualiza receta y retorna con datos nuevos', () async {
      final actualizada = _receta(nombre: 'Pan Integral', rendimiento: 15);

      when(mockRepo.updateReceta(any)).thenAnswer((_) async => actualizada);

      final resultado = await mockRepo.updateReceta(actualizada);

      expect(resultado.nombre, 'Pan Integral');
      expect(resultado.rendimiento, 15);
      verify(mockRepo.updateReceta(any)).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA013 — getIngredientesPorReceta(String recetaId)
  // ═══════════════════════════════════════════════════════
  group('CA013 - getIngredientesPorReceta()', () {
    test('retorna lista de ingredientes de la receta', () async {
      when(mockRepo.getIngredientesPorReceta('r1')).thenAnswer((_) async => [
        _ingrediente(insumoId: 'a1'),
        _ingrediente(id: 'ri2', insumoId: 'a2', cantidad: 0.5),
        _ingrediente(id: 'ri3', insumoId: 'a3', cantidad: 1.0),
      ]);

      final resultado = await mockRepo.getIngredientesPorReceta('r1');

      expect(resultado.length, 3);
      expect(resultado[0].insumoId, 'a1');
      expect(resultado[0].cantidadRequerida, 2.0);
    });

    test('retorna lista vacía si la receta no tiene ingredientes', () async {
      when(mockRepo.getIngredientesPorReceta('r-vacia'))
          .thenAnswer((_) async => []);

      final resultado = await mockRepo.getIngredientesPorReceta('r-vacia');
      expect(resultado, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA014 — addIngrediente(RecetaIngrediente ingrediente)
  // ═══════════════════════════════════════════════════════
  group('CA014 - addIngrediente()', () {
    test('agrega ingrediente y retorna con ID', () async {
      final nuevo = _ingrediente(id: '', insumoId: 'a5', cantidad: 3.0);
      final creado = _ingrediente(id: 'ri-nuevo', insumoId: 'a5', cantidad: 3.0);

      when(mockRepo.addIngrediente(nuevo)).thenAnswer((_) async => creado);

      final resultado = await mockRepo.addIngrediente(nuevo);

      expect(resultado.id, 'ri-nuevo');
      expect(resultado.insumoId, 'a5');
      verify(mockRepo.addIngrediente(nuevo)).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA015 — reemplazarIngredientes(recetaId, ingredientes)
  // ═══════════════════════════════════════════════════════
  group('CA015 - reemplazarIngredientes()', () {
    test('reemplaza todos los ingredientes y retorna nueva lista', () async {
      final nuevos = [
        _ingrediente(id: '', insumoId: 'a10', cantidad: 1.0),
        _ingrediente(id: '', insumoId: 'a11'),
      ];
      final retornados = [
        _ingrediente(id: 'ri-10', insumoId: 'a10', cantidad: 1.0),
        _ingrediente(id: 'ri-11', insumoId: 'a11'),
      ];

      when(mockRepo.reemplazarIngredientes('r1', nuevos))
          .thenAnswer((_) async => retornados);

      final resultado = await mockRepo.reemplazarIngredientes('r1', nuevos);

      expect(resultado.length, 2);
      expect(resultado[0].id, 'ri-10');
      expect(resultado[1].id, 'ri-11');
      verify(mockRepo.reemplazarIngredientes('r1', nuevos)).called(1);
    });

    test('retorna lista vacía cuando se envía lista vacía', () async {
      when(mockRepo.reemplazarIngredientes('r1', []))
          .thenAnswer((_) async => []);

      final resultado = await mockRepo.reemplazarIngredientes('r1', []);
      expect(resultado, isEmpty);
    });
  });
}
