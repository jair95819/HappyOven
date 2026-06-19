import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/receta.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // CA024 — Receta.fromJson(Map)
  // Deserializar JSON. Maneja keys alternativas:
  // producto_id/articulo_id, instrucciones/preparacion
  // ═══════════════════════════════════════════════════════
  group('CA024 - Receta.fromJson()', () {
    test('crea Receta desde JSON con campos estándar', () {
      final json = {
        'id': 'r1',
        'nombre': 'Pan de molde',
        'producto_id': 'p1',
        'instrucciones': 'Mezclar y hornear 30min',
        'rendimiento_unidades': 10,
        'created_at': '2025-06-01T00:00:00Z',
      };

      final receta = Receta.fromJson(json);

      expect(receta.id, 'r1');
      expect(receta.nombre, 'Pan de molde');
      expect(receta.productoId, 'p1');
      expect(receta.instrucciones, 'Mezclar y hornear 30min');
      expect(receta.rendimiento, 10.0);
    });

    test('usa articulo_id como fallback de producto_id', () {
      final json = {
        'id': 'r2',
        'nombre': 'Galletas',
        'articulo_id': 'a-005',
        'rendimiento_unidades': 20,
      };

      final receta = Receta.fromJson(json);
      expect(receta.productoId, 'a-005');
    });

    test('usa preparacion como fallback de instrucciones', () {
      final json = {
        'id': 'r3',
        'nombre': 'Brownie',
        'preparacion': 'Paso 1: mezclar. Paso 2: hornear.',
      };

      final receta = Receta.fromJson(json);
      expect(receta.instrucciones, 'Paso 1: mezclar. Paso 2: hornear.');
    });

    test('rendimiento es 0.0 cuando rendimiento_unidades es null', () {
      final json = {
        'id': 'r4',
        'nombre': 'Test',
      };

      final receta = Receta.fromJson(json);
      expect(receta.rendimiento, 0.0);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA025 — Receta.toJson()
  // Serializar Receta a JSON para BD
  // ═══════════════════════════════════════════════════════
  group('CA025 - Receta.toJson()', () {
    test('serializa con rendimiento como entero', () {
      final receta = Receta(
        id: 'r1', nombre: 'Pan', rendimiento: 12.0,
        createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

      final json = receta.toJson();

      expect(json['rendimiento_unidades'], isA<int>());
      expect(json['rendimiento_unidades'], 12);
    });

    test('omite id cuando está vacío', () {
      final receta = Receta(
        id: '', nombre: 'Pan', rendimiento: 10,
        createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

      expect(receta.toJson().containsKey('id'), false);
    });

    test('incluye producto_id', () {
      final receta = Receta(
        id: 'r1', nombre: 'Pan', productoId: 'p1',
        rendimiento: 10, createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

      expect(receta.toJson()['producto_id'], 'p1');
    });
  });
}
