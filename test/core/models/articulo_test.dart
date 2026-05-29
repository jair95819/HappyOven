import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/articulo.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // CA022 — Articulo.fromJson(Map)
  // Deserializar JSON a Articulo. Maneja valores nulos con defaults.
  // ═══════════════════════════════════════════════════════
  group('CA022 - Articulo.fromJson()', () {
    test('crea Articulo desde JSON completo', () {
      final json = {
        'id': 'a1',
        'nombre': 'Harina de trigo',
        'categoria_id': 'cat-01',
        'tipo': 'insumo',
        'unidad': 'kg',
        'stock_actual': 50.0,
        'stock_minimo': 5.0,
        'precio_unitario': 3.50,
        'activo': true,
        'created_at': '2025-01-15T10:30:00Z',
        'updated_at': '2025-03-20T14:00:00Z',
      };

      final articulo = Articulo.fromJson(json);

      expect(articulo.id, 'a1');
      expect(articulo.nombre, 'Harina de trigo');
      expect(articulo.categoriaId, 'cat-01');
      expect(articulo.tipo, 'insumo');
      expect(articulo.unidad, 'kg');
      expect(articulo.stockActual, 50.0);
      expect(articulo.stockMinimo, 5.0);
      expect(articulo.precioUnitario, 3.50);
      expect(articulo.activo, true);
    });

    test('usa defaults cuando campos opcionales son null', () {
      final json = {
        'id': 'a2',
        'nombre': 'Test',
        'tipo': 'insumo',
      };

      final articulo = Articulo.fromJson(json);

      expect(articulo.unidad, 'unidades');
      expect(articulo.stockActual, 0.0);
      expect(articulo.stockMinimo, 0.0);
      expect(articulo.precioUnitario, 0.0);
      expect(articulo.activo, true);
      expect(articulo.categoriaId, isNull);
    });

    test('parsea created_at y updated_at correctamente', () {
      final json = {
        'id': 'a3',
        'nombre': 'Test',
        'tipo': 'insumo',
        'created_at': '2025-06-01T12:00:00Z',
        'updated_at': '2025-06-15T18:30:00Z',
      };

      final articulo = Articulo.fromJson(json);

      expect(articulo.createdAt.year, 2025);
      expect(articulo.createdAt.month, 6);
      expect(articulo.updatedAt.day, 15);
    });

    test('usa DateTime.now() cuando created_at es null', () {
      final json = {
        'id': 'a4',
        'nombre': 'Test',
        'tipo': 'insumo',
      };

      final antes = DateTime.now();
      final articulo = Articulo.fromJson(json);
      final despues = DateTime.now();

      expect(
        articulo.createdAt.isAfter(antes.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        articulo.createdAt.isBefore(despues.add(const Duration(seconds: 1))),
        true,
      );
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA023 — Articulo.toJson()
  // Serializar Articulo a mapa JSON para envío a BD
  // ═══════════════════════════════════════════════════════
  group('CA023 - Articulo.toJson()', () {
    test('incluye todos los campos esperados', () {
      final articulo = Articulo(
        id: 'a1', nombre: 'Harina', categoriaId: 'cat-01',
        tipo: 'insumo', unidad: 'kg', stockActual: 50,
        stockMinimo: 5, precioUnitario: 3.5, activo: true,
        createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

      final json = articulo.toJson();

      expect(json['id'], 'a1');
      expect(json['nombre'], 'Harina');
      expect(json['categoria_id'], 'cat-01');
      expect(json['tipo'], 'insumo');
      expect(json['unidad'], 'kg');
      expect(json['stock_actual'], 50);
      expect(json['stock_minimo'], 5);
      expect(json['precio_unitario'], 3.5);
      expect(json['activo'], true);
    });

    test('omite id cuando está vacío', () {
      final articulo = Articulo(
        id: '', nombre: 'Test', categoriaId: null,
        tipo: 'insumo', unidad: 'kg', stockActual: 0,
        stockMinimo: 0, precioUnitario: 0, activo: true,
        createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

      expect(articulo.toJson().containsKey('id'), false);
    });

    test('incluye id cuando no está vacío', () {
      final articulo = Articulo(
        id: 'abc-123', nombre: 'Test', categoriaId: null,
        tipo: 'insumo', unidad: 'kg', stockActual: 0,
        stockMinimo: 0, precioUnitario: 0, activo: true,
        createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

      expect(articulo.toJson()['id'], 'abc-123');
    });
  });
}
