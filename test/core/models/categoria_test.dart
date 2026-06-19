import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/categoria.dart';

void main() {
  group('Categoria model', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = {
        'id': 'cat1',
        'nombre': 'Harinas',
        'tipo': 'insumo',
        'orden': 1,
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final cat = Categoria.fromJson(json);
      expect(cat.id, 'cat1');
      expect(cat.nombre, 'Harinas');
      expect(cat.tipo, TipoArticulo.insumo);
      expect(cat.orden, 1);
      expect(cat.createdAt, DateTime.utc(2026, 6, 1, 10, 0, 0));
    });

    test('fromJson convierte correctamente tipo producto_final', () {
      final json = {
        'id': 'cat2',
        'nombre': 'Panadería',
        'tipo': 'producto_final',
        'orden': 2,
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final cat = Categoria.fromJson(json);
      expect(cat.tipo, TipoArticulo.productoFinal);
    });

    test('fromJson usa safeCast para orden (num → int)', () {
      final json = {
        'id': 'cat3',
        'nombre': 'Lácteos',
        'tipo': 'insumo',
        'orden': 3.0,
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final cat = Categoria.fromJson(json);
      expect(cat.orden, 3);
    });

    test('fromJson usa valor por defecto para orden null', () {
      final json = {
        'id': 'cat4',
        'nombre': 'Bebidas',
        'tipo': 'insumo',
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final cat = Categoria.fromJson(json);
      expect(cat.orden, 0);
    });

    test('toJson serializa correctamente', () {
      final cat = Categoria(
        id: 'cat1',
        nombre: 'Harinas',
        tipo: TipoArticulo.insumo,
        orden: 1,
        createdAt: DateTime.utc(2026, 6, 1, 10, 0, 0),
      );
      final json = cat.toJson();
      expect(json['id'], 'cat1');
      expect(json['nombre'], 'Harinas');
      expect(json['tipo'], 'insumo');
      expect(json['orden'], 1);
    });

    test('toJson omite id si está vacío', () {
      final cat = Categoria(
        id: '',
        nombre: 'Nueva',
        tipo: TipoArticulo.productoFinal,
        orden: 5,
        createdAt: DateTime.now(),
      );
      final json = cat.toJson();
      expect(json.containsKey('id'), false);
    });

    test('fromJson maneja created_at null', () {
      final json = {
        'id': 'cat5',
        'nombre': 'Test',
        'tipo': 'insumo',
        'orden': 0,
      };
      final cat = Categoria.fromJson(json);
      expect(cat.createdAt, isA<DateTime>());
    });
  });
}
