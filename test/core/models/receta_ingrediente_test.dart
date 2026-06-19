import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';

void main() {
  group('RecetaIngrediente model', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = {
        'id': 'ri1',
        'receta_id': 'rec1',
        'insumo_id': 'ins1',
        'cantidad_requerida': 2.5,
      };
      final ri = RecetaIngrediente.fromJson(json);
      expect(ri.id, 'ri1');
      expect(ri.recetaId, 'rec1');
      expect(ri.insumoId, 'ins1');
      expect(ri.cantidadRequerida, 2.5);
    });

    test('fromJson usa valor por defecto para cantidad_requerida', () {
      final json = {
        'id': 'ri2',
        'receta_id': 'rec1',
        'insumo_id': 'ins1',
      };
      final ri = RecetaIngrediente.fromJson(json);
      expect(ri.cantidadRequerida, 0.0);
    });

    test('fromJson convierte num a double correctamente', () {
      final json = {
        'id': 'ri3',
        'receta_id': 'rec1',
        'insumo_id': 'ins1',
        'cantidad_requerida': 3,
      };
      final ri = RecetaIngrediente.fromJson(json);
      expect(ri.cantidadRequerida, 3.0);
    });

    test('toJson serializa correctamente', () {
      final ri = RecetaIngrediente(
        id: 'ri1',
        recetaId: 'rec1',
        insumoId: 'ins1',
        cantidadRequerida: 2.5,
      );
      final json = ri.toJson();
      expect(json['id'], 'ri1');
      expect(json['receta_id'], 'rec1');
      expect(json['insumo_id'], 'ins1');
      expect(json['cantidad_requerida'], 2.5);
    });

    test('toJson omite id si está vacío', () {
      final ri = RecetaIngrediente(
        id: '',
        recetaId: 'rec1',
        insumoId: 'ins1',
        cantidadRequerida: 1.0,
      );
      final json = ri.toJson();
      expect(json.containsKey('id'), false);
    });
  });
}
