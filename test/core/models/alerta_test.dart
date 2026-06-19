import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/alerta.dart';

void main() {
  group('Alerta model', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = {
        'id': 'a1',
        'articulo_id': 'art1',
        'tipo': 'stock_bajo',
        'titulo': 'Stock bajo',
        'mensaje': 'Stock de Harina por debajo del mínimo.',
        'leida': false,
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final alerta = Alerta.fromJson(json);
      expect(alerta.id, 'a1');
      expect(alerta.articuloId, 'art1');
      expect(alerta.tipo, TipoAlerta.stockBajo);
      expect(alerta.titulo, 'Stock bajo');
      expect(alerta.mensaje, 'Stock de Harina por debajo del mínimo.');
      expect(alerta.leida, false);
      expect(alerta.createdAt, DateTime.utc(2026, 6, 1, 10, 0, 0));
    });

    test('fromJson maneja null en articulo_id y leida', () {
      final json = {
        'id': 'a2',
        'tipo': 'anomalia',
        'titulo': 'Anomalía',
        'mensaje': 'Consumo inusual detectado.',
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final alerta = Alerta.fromJson(json);
      expect(alerta.articuloId, isNull);
      expect(alerta.leida, false);
      expect(alerta.tipo, TipoAlerta.anomalia);
    });

    test('fromJson usa valor por defecto para tipo desconocido', () {
      final json = {
        'id': 'a3',
        'tipo': 'tipo_desconocido',
        'titulo': 'Test',
        'mensaje': 'Mensaje',
        'leida': false,
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final alerta = Alerta.fromJson(json);
      expect(alerta.tipo, TipoAlerta.stockBajo);
    });

    test('toJson serializa correctamente', () {
      final alerta = Alerta(
        id: 'a1',
        articuloId: 'art1',
        tipo: TipoAlerta.stockBajo,
        titulo: 'Stock bajo',
        mensaje: 'Mensaje de alerta',
        leida: true,
        createdAt: DateTime.utc(2026, 6, 1, 10, 0, 0),
      );
      final json = alerta.toJson();
      expect(json['id'], 'a1');
      expect(json['articulo_id'], 'art1');
      expect(json['tipo'], 'stock_bajo');
      expect(json['titulo'], 'Stock bajo');
      expect(json['mensaje'], 'Mensaje de alerta');
      expect(json['leida'], true);
    });

    test('toJson omite id si está vacío', () {
      final alerta = Alerta(
        id: '',
        articuloId: 'art1',
        tipo: TipoAlerta.stockBajo,
        titulo: 'Stock bajo',
        mensaje: 'Mensaje',
        leida: false,
        createdAt: DateTime.now(),
      );
      final json = alerta.toJson();
      expect(json.containsKey('id'), false);
    });

    test('fromJson maneja created_at null', () {
      final json = {
        'id': 'a4',
        'tipo': 'ingreso',
        'titulo': 'Ingreso',
        'mensaje': 'Nuevo ingreso registrado.',
        'leida': false,
      };
      final alerta = Alerta.fromJson(json);
      expect(alerta.createdAt, isA<DateTime>());
      expect(alerta.tipo, TipoAlerta.ingreso);
    });
  });
}
